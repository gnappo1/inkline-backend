class FriendshipsController < ApplicationController
  before_action :bounce_if_not_logged_in

  DEFAULT_LIMIT = 20

  # GET /friendships?limit=20&before=<cursor>&after=<cursor>
  def index
    limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, 100)

    rel = Friendship
            .where("sender_id = :id OR receiver_id = :id", id: @current_user.id)
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

    render json: {
      data: rows.map { |fr| friendship_json(fr, @current_user.id) },
      next_cursor: rows.last && encode_cursor(rows.last),
      prev_cursor: rows.first && encode_cursor(rows.first)
    }, status: 200
  end

  def create
    receiver_id = params.require(:receiver_id).to_i
  
    return render(json: { error: "You cannot befriend yourself" }, status: 422) if @current_user.id == receiver_id
    return render(json: { error: "User not found" }, status: 404) unless User.exists?(id: receiver_id)
  
    me = @current_user.id
  
    fr = nil
    Friendship.transaction do
      fr = Friendship.between(me, receiver_id).lock(true).first
  
      if fr.nil?
        fr = @current_user.send_friend_request(receiver_id)
      else
        case fr.status
        when "blocked"
          return render json: { error: "Blocked" }, status: 403
  
        when "accepted"
          return render json: fr, status: 200
  
        when "pending"
          if fr.sender_id == me
            return render json: fr, status: 200
          elsif fr.receiver_id == me
            # Optional policy: auto accept if the other side tries to send back
            fr.update!(status: :accepted)
            return render json: fr, status: 200
          end
  
        when "declined", "canceled"
          fr.update!(status: :pending, sender_id: me, receiver_id: receiver_id)
          return render json: fr, status: 200
        end
      end
    end
  
    render json: fr, status: 201
  rescue ActiveRecord::RecordNotUnique
    # Unique pair constraint fired due to a race. Return the existing row.
    fr = Friendship.between(me, receiver_id).first
    render json: fr, status: 200
  end
  

  def update
    fr = Friendship.find_by(id: params[:id])
    return render json: { error: "Not found" }, status: 404 unless fr
    return render json: { error: "Unauthorized" }, status: 403 unless participant?(fr, @current_user.id)

    other_id = other_party_id(fr, @current_user.id)
    op = params.require(:action).to_s
    return render json: { error: "Unsupported action" }, status: 422 unless %w[accept reject].include?(op)

    fr = @current_user.respond_to_friendship!(other_id, op)
    render json: friendship_json(fr, @current_user.id), status: 200
  end

  def destroy
    fr = Friendship.find_by(id: params[:id])
    return render json: { error: "Not found" }, status: 404 unless fr
    return render json: { error: "Unauthorized" }, status: 403 unless participant?(fr, @current_user.id)
  
    other_id = other_party_id(fr, @current_user.id)
  
    if fr.pending? && fr.sender_id == @current_user.id
      @current_user.respond_to_friendship!(other_id, :cancel)
      return head 204
    end
  
    if fr.accepted?
      @current_user.respond_to_friendship!(other_id, :unfriend)
      return head 204
    end
  
    render json: { error: "Invalid state for delete" }, status: 422
  end

  private

  def participant?(fr, me_id)
    fr.sender_id == me_id || fr.receiver_id == me_id
  end

  def other_party_id(fr, me_id)
    fr.sender_id == me_id ? fr.receiver_id : fr.sender_id
  end

  # minimal payload for the list, React can split by status and who is who
  def friendship_json(fr, me_id)
    {
      id: fr.id,
      status: fr.status,
      created_at: fr.created_at,
      sender_id: fr.sender_id,
      receiver_id: fr.receiver_id,
      sender:   { id: fr.sender.id,   first_name: fr.sender.first_name,   last_name: fr.sender.last_name },
      receiver: { id: fr.receiver.id, first_name: fr.receiver.first_name, last_name: fr.receiver.last_name }
    }
  end
  
end