class UsersController < ApplicationController
  before_action :bounce_clients, only: [:index]
  before_action :bounce_if_not_logged_in
  before_action :find_user, only: [:show, :update, :destroy]

  DEFAULT_LIMIT = 20

  def friends
    limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, 100)

    rel = Friendship.accepted
                    .where("sender_id = :me OR receiver_id = :me", me: @current_user.id)
                    .includes(:sender, :receiver)
                    .order(created_at: :desc, id: :desc)

    if params[:before].present?
      ts, fid = decode_cursor(params[:before])
      rel = rel.where("created_at < ? OR (created_at = ? AND id < ?)", ts, ts, fid)
    elsif params[:after].present?
      ts, fid = decode_cursor(params[:after])
      rel = rel.where("created_at > ? OR (created_at = ? AND id > ?)", ts, ts, fid)
               .reorder(created_at: :asc, id: :asc)
    end

    rows = rel.limit(limit).to_a
    rows.reverse! if params[:after].present?

    meta = {
      next_cursor: rows.last && encode_cursor(rows.last),
      prev_cursor: rows.first && encode_cursor(rows.first)
    }

    fields = { users: %i[first_name last_name] }

    render_jsonapi(
      rows,
      serializer: FriendshipSerializer,
      include: [:sender, :receiver],
      fields: fields,
      meta: meta
    )
  end

  def index
    render_jsonapi(User.order(created_at: :desc, id: :desc), serializer: UserSerializer)
  end

  def show
    return render json: { msg: "Could not find user with id ##{params[:id]}" }, status: 404 unless @user
    allowed =
      @current_user.id == @user.id ||
      @current_user.admin? ||
      @current_user.superadmin? ||
      Friendship.between(@current_user.id, @user.id).where(status: :accepted).exists?

    return render json: { error: "Unauthorized" }, status: 403 unless allowed

    render_jsonapi(@user, serializer: UserSerializer, status: 200)
  end

  def update
    return render json: { error: "Not found" }, status: 404 unless @current_user
  
    u = user_params
    wants_sensitive_update =
      u.key?(:first_name) || u.key?(:last_name) || u.key?(:email) ||
      u.key?(:password)   || u.key?(:password_confirmation)

    if wants_sensitive_update
      cur = params.dig(:user, :current_password).to_s
      unless @current_user.authenticate(cur)
        return render json: { error: "Current password is incorrect" }, status: 403
      end
    end

    updates = u.slice(:first_name, :last_name, :email)
    if u[:password].present?
      updates[:password] = u[:password]
    end

    if @current_user.update(updates)
      render_jsonapi(@current_user, serializer: UserSerializer, status: 202)
    else
      render json: { errors: @current_user.errors.full_messages }, status: 400
    end
  end

  def summary
      me = @current_user.id

      notes_count = Note.where(user_id: me).count
      friends_count = Friendship.where(status: :accepted).where("sender_id = :me OR receiver_id = :me", me: me).count
      render json: { notes_count:, friends_count: }, status: 200
  end

  def destroy
    return render json: { error: "Not found" }, status: 404 unless @user
    unless @current_user.admin? || @current_user.superadmin? || @current_user.id == @user.id
      return render json: { error: "Unauthorized" }, status: 403
    end
    @user.destroy
    session.delete(:user_id) if @user.id == @current_user.id
    head 204
  end

  def search
    q = params[:q].to_s.strip
    return render json: { data: [] }, status: 200 if q.blank?
  
    like = "%#{q.downcase}%"
  
    base = User
      .where.not(id: @current_user.id)
      .where(
        "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(first_name || ' ' || last_name) LIKE :q",
        q: like
      )
      .order(:first_name, :last_name)
      .limit(20)
  
    candidate_ids = base.pluck(:id)
    frs = Friendship
      .where("(sender_id = :me AND receiver_id IN (:ids)) OR (receiver_id = :me AND sender_id IN (:ids))",
             me: @current_user.id, ids: candidate_ids)
      .select(:id, :status, :sender_id, :receiver_id)
      .to_a
  
    fr_by_other_id = {}
    frs.each do |f|
      other = (f.sender_id == @current_user.id) ? f.receiver_id : f.sender_id
      fr_by_other_id[other] = f
    end

    filtered = base.to_a.reject do |u|
      fr = fr_by_other_id[u.id]
      fr && fr.status == "blocked"
    end
  
    payload = UserMiniSerializer.new(filtered, {
      params: { current_user: @current_user },
      meta: nil
    }).serializable_hash
  
    payload[:data].each do |row|
      uid = row[:id].to_i
      fr  = fr_by_other_id[uid]
  
      rel =
        if fr.nil?
          "none"
        elsif fr.status == "accepted"
          "friend"
        elsif fr.status == "pending" && fr.sender_id == @current_user.id
          "pending_sent"
        elsif fr.status == "pending" && fr.receiver_id == @current_user.id
          "pending_incoming"
        elsif fr.status == "blocked"
          "blocked"
        else
          "none"
        end
  
      row[:meta] = {
        relationship: rel,
        friendship_id: fr&.id
      }
    end
  
    render json: payload, status: 200
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password)
  end

  def find_user
    @user = User.find_by(id: params[:id])
  end

  def encode_cursor(fr)
    Base64.urlsafe_encode64("#{fr.created_at.utc.iso8601},#{fr.id}")
  end

  def decode_cursor(str)
    ts_s, id_s = Base64.urlsafe_decode64(str).split(",", 2)
    [Time.iso8601(ts_s), Integer(id_s)]
  end
end
