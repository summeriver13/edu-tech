Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

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
