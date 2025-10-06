class UsersController < ApplicationController
  before_action :bounce_clients, only: [:index]
  before_action :bounce_if_not_logged_in, only: [:show, :update, :destroy]
  before_action :find_user, only: [:show, :update, :destroy]
  before_action :bounce_if_not_logged_in, only: [:friends]

  DEFAULT_LIMIT = 20

  # GET /me/friends?limit=20&before=<cursor>&after=<cursor>
  def friends
    limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, 100)

    rel = Friendship.accepted
                    .where("sender_id = :me OR receiver_id = :me", me: @current_user.id)
                    .includes(:sender, :receiver)
                    .order(created_at: :desc, id: :desc)

    # keyset cursors
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

    # emit the "other" user for each friendship
    payload = rows.map do |fr|
      other = (fr.sender_id == @current_user.id) ? fr.receiver : fr.sender
      {
        friendship_id: fr.id,
        friended_at: fr.created_at,
        friend: {
          id: other.id,
          first_name: other.first_name,
          last_name:  other.last_name
          # add :avatar_url when you have it
        }
      }
    end

    render json: {
      data: payload,
      next_cursor: rows.last && encode_cursor(rows.last),   # use as ?before=
      prev_cursor: rows.first && encode_cursor(rows.first)  # use as ?after=
    }, status: 200
  end
  
  def index
    render json: User.order(created_at: :desc, id: :desc), status: 200
  end

  def show
    render json: {msg: "Could not find user with id ##{params[:id]}"}, status: 404 unless @user
    unless @current_user.admin? || @current_user.superadmin? || @current_user.id == @user.id
      return render json: { error: "Unauthorized" }, status: 403
    end
    render json: @user, status: 200
  end

  def update
    return render json: { error: "Not found" }, status: 404 unless @user
    unless @current_user.admin? || @current_user.superadmin? || @current_user.id == @user.id
      return render json: { error: "Unauthorized" }, status: 403
    end
    if @user.update(user_params)
      render json: @user, status: 202
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
end
