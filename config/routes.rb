Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resource :password, only: %i[ edit update ]

  resources :home , only: [:index]
  resources :courses do
    member do
      get 'information'
    end
    resources :resources
    resources :activities
  end
  resources :users
end
