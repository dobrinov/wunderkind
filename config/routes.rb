Rails.application.routes.draw do
  get "canvas", to: "static_pages#canvas"

  get "sign-up", to: "users#new"
  post "sign-up", to: "users#create"
  get "sign-in", to: "sessions#new"
  post "sign-in", to: "sessions#create"
  delete "sign-out", to: "sessions#destroy"

  get "assignments", to: "assignments#index"
  post "assignments", to: "assignments#create"
  get "assignments/:id", to: "assignments#show", as: :assignment
  get "assignments/:id/summary", to: "assignments#summary", as: :assignment_summary
  get "questions/:id", to: "assignment_questions#show", as: :question
  get "questions/:question_id/answer", to: "answers#show", as: :question_answer
  post "questions/:question_id/answer", to: "answers#create"

  resource :profile, only: [ :show, :update ]

  resource :calendar, only: [ :show ] do
    get ":date/assignments", to: "assignments#index", as: :daily_assignments
  end

  namespace :overseer do
    resources :questions, except: [ :show, :destroy ]
    resources :question_images, only: [ :index ]
    resources :question_scripts, only: [ :index ]
    resources :users, only: [ :index ]
    resources :topics, only: [ :index, :new, :create ]

    root to: "questions#index", as: :root
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#landingpage"
end
