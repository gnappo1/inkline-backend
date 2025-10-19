class HealthController < ApplicationController
  def show
    render json: {
      ok: true,
      env: Rails.env,
      time: Time.now.utc.iso8601
    }, status: :ok
  end
end