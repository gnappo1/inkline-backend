class SessionsController < ApplicationController
  before_action :bounce_if_not_logged_in, only: [:current_user, :logout]

  def login
    user_params = params.require(:user).permit(:email, :password)
    user = User.find_by(email: user_params[:email])
    if user&.authenticate(user_params[:password])
      session["user_id"] = user.id
      render json: user, status: 200
    else
      render json: {msg: "Invalid Credentials"}, status: 400
    end
  end

  def signup
    user = User.new(user_params)
    if user.save
      session["user_id"] = user.id
      render json: user, status: 201
    else
      render json: {msg: user.errors}, status: 400
    end
  end

  def logout
    session.delete(:user_id)
    head 204
  end

  def current_user
    render json: @current_user, status: 200
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password)
  end

end