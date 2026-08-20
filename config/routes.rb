Rails.application.routes.draw do
  get "sign-up", to: "users#new"
  post "sign-up", to: "users#create"
  get "sign-in", to: "sessions#new"
  post "sign-in", to: "sessions#create"
  delete "sign-out", to: "sessions#destroy"

  get "verify-email/:token", to: "email_verifications#show", as: :verify_email
  post "verify-email", to: "email_verifications#create", as: :email_verifications
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token

  get "assignments", to: "assignments#index"
  post "assignments", to: "assignments#create"
  post "assignments/daily", to: "assignments#create_daily", as: :daily_assignment
  get "assignments/:id", to: "assignments#show", as: :assignment
  get "assignments/:id/summary", to: "assignments#summary", as: :assignment_summary
  get "questions/:id", to: "assignment_questions#show", as: :question
  get "questions/:question_id/answer", to: "answers#show", as: :question_answer
  post "questions/:question_id/answer", to: "answers#create"

  resource :profile, only: [ :show, :update ] do
    post :link_code
  end

  resource :calendar, only: [ :show ] do
    get ":date/assignments", to: "assignments#index", as: :daily_assignments
  end

  resources :classrooms, only: [ :index ] do
    collection do
      post :join
    end
  end

  get "leaderboard", to: "leaderboards#show", as: :leaderboard
  patch "answer_overrides/:id", to: "answer_overrides#update", as: :answer_override

  namespace :teachers do
    resources :classrooms
    resources :homeworks, only: [ :new, :create, :show ]
    resources :questions, except: [ :show, :destroy ] do
      member do
        post :submit_for_review
      end
    end
  end

  namespace :parents do
    resources :children, only: [ :index, :new, :create ]
    resources :homeworks, only: [ :new, :create, :show ]
  end

  get "design-system", to: "design_system#show", as: :design_system

  namespace :overseer do
    resources :questions, except: [ :show, :destroy ] do
      member do
        get :preview
      end
      resource :hint, only: [ :show, :update ], controller: "hints"
    end
    resources :reviews, only: [ :index ] do
      member do
        post :approve
        post :reject
      end
    end
    resources :question_images, only: [ :index ]
    resources :users, only: [ :index ]
    resources :topics, only: [ :index, :new, :create, :edit, :update ]

    root to: "questions#index", as: :root
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#landingpage"
end
