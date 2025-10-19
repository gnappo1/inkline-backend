class ApplicationController < ActionController::API
  include ActionController::Cookies
  include JsonapiRendering
  protect_from_forgery with: :null_session

  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

  private

  def load_user
    @current_user ||= session[:user_id] && User.find_by(id: session[:user_id])
  end

  def bounce_if_not_logged_in
    load_user || (render json: { msg: "Unknown user, please log in!" }, status: 401)
  end

  def bounce_clients
    return if load_user && (@current_user.admin? || @current_user.superadmin?)
    render json: { error: "Unauthorized" }, status: 403
  end

  def render_unprocessable(ex)
    record = ex.record
    render json: { errors: record&.errors || [ex.message] }, status: 422
  end

  def render_not_found(_ex)
    render json: { error: "Not found" }, status: 404
  end

  def render_conflict(_ex)
    render json: { error: "Conflict - record not unique" }, status: 409
  end

  def encode_cursor(fr)
    Base64.urlsafe_encode64("#{fr.created_at.utc.iso8601},#{fr.id}")
  end

  def decode_cursor(str)
    ts_s, id_s = Base64.urlsafe_decode64(str).split(",", 2)
    [Time.iso8601(ts_s), Integer(id_s)]
  end
end
