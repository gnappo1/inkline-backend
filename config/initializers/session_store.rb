Rails.application.config.session_store :cookie_store,
  key: '_inkline_api_session',
  domain: ENV['SESSION_COOKIE_DOMAIN'].presence,
  tld_length: 2,
  same_site: :lax,
  secure: Rails.env.production?