class UsersController < ApplicationController
  before_action :bounce_clients, only: [:index]
  before_action :bounce_if_not_logged_in, only: [:show, :update, :destroy, :friends]
  before_action :find_user, only: [:show, :update, :destroy]

  DEFAULT_LIMIT = 20

  # GET /me/friends?limit=20&before=<cursor>&after=<cursor>
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

    # Include both ends; client knows current user and can display the "other".
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
    unless @current_user.admin? || @current_user.superadmin? || @current_user.id == @user.id
      return render json: { error: "Unauthorized" }, status: 403
    end
    render_jsonapi(@user, serializer: UserSerializer, status: 200)
  end

  def update
    return render json: { error: "Not found" }, status: 404 unless @user
    unless @current_user.admin? || @current_user.superadmin? || @current_user.id == @user.id
      return render json: { error: "Unauthorized" }, status: 403
    end

    if @user.update(user_params)
      render_jsonapi(@user, serializer: UserSerializer, status: 202)
    else
      render json: { errors: @user.errors }, status: 400
    end
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

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password)
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
