Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_ORIGIN", "https://app.inkline.live")
    resource "*", headers: :any, methods: %i[get post patch put delete options head], credentials: true
  end
end

