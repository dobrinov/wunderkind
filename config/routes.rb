Rails.application.routes.draw do
  get "canvas", to: "static_pages#canvas"

  get "sign-up", to: "users#new"
  post "sign-up", to: "users#create"
  get "sign-in", to: "sessions#new"
  post "sign-in", to: "sessions#create"
  delete "sign-out", to: "sessions#destroy"

  resource :calendar, only: [ :show ] do
    get ":date/assignments", to: "assignments#index", as: :daily_assignments
  end

  resources :assignments, only: [ :create, :show ] do
    get "completion-summary", on: :member, action: :completion_summary, as: :completion_summary
    resources :questions, only: [ :show ] do
      resource :answer, only: [ :create, :show ]
    end
  end

  namespace :overseer do
    resources :questions, except: [ :show, :destroy ]
    resources :users, only: [ :index ]

    root to: "questions#index", as: :root
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#landingpage"
end
