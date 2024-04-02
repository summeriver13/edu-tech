Rails.application.routes.draw do
  resources :courses
 root "home#index"

  get "/home", to: "home#index"
  get "/course", to: "courses#index"
  get "/classroom", to: "classrooms#index"
  get "/about", to: "about#index"
  get "/upload", to: "uploads#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
