Rails.application.config.session_store :cookie_store,
  key: '_inkline_api_session',
  domain: (ENV['SESSION_COOKIE_DOMAIN'].presence || :all),                                    # <- works for subdomains
  tld_length: 2,                                   # "inkline.live"
  same_site: :lax,                                 # now same-site with subdomains
  secure: Rails.env.production?