Rails.application.routes.draw do
  resources :notes
  resources :friendships, except: [:show]
  get "/users/search", to: "users#search"
  resources :users, except: [:create, :update]

  post "/signup", to: "sessions#signup", as: "signup"
  post "/login", to: "sessions#login", as: "login"
  get "/me", to: "sessions#current_user", as: "current_user"
  get "/me/summary", to: "users#summary", as: "user_summary"
  delete "/logout", to: "sessions#logout", as: "logout"
  get "/me/friends", to: "users#my_friends"
  patch "/profile/update", to: "users#update"
  get "/feed/public", to: "feeds#public_notes"
  
  get "up", to: "health#show", as: :rails_health_check
  root to: "health#show"
end
