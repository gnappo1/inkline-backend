Rails.application.routes.draw do
  resources :notes
  resources :friendships, except: [:show]
  resources :users, except: [:create]

  post "/signup", to: "sessions#signup", as: "signup"
  post "/login", to: "sessions#login", as: "login"
  get "/me", to: "sessions#current_user", as: "current_user"
  delete "/logout", to: "sessions#logout", as: "logout"
  get "/me/friends", to: "users#my_friends"
  get "/feed/public", to: "feeds#public_notes"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
