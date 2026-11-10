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
      post 'sync'
    end
    resources :resources
    resources :activities
    resources :memberships, only: %i[ index create destroy ]
    resources :assessments do
      resource :submission, only: %i[ create update ]
      resources :submissions, only: [] do
        resource :grade, only: %i[ update ]
      end
    end
    resources :groups, only: %i[ index create destroy ] do
      resources :group_memberships, only: %i[ create destroy ]
    end
    resources :contributions, only: %i[ index create destroy ]
    resources :grades, only: %i[ index ]
    resources :questions, only: %i[ index new create destroy ]
    resource :practice, only: %i[ show create ], controller: "practice"
    resources :attempts, only: %i[ show ]
  end
  get "courses/:course_id/practice/mistakes", to: "practice#mistakes", as: :course_practice_mistakes
  resources :users
end
