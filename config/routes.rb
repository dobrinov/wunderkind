Rails.application.routes.draw do
  get "canvas", to: "static_pages#canvas"

  get "sign-up", to: "users#new"
  post "sign-up", to: "users#create"
  get "sign-in", to: "sessions#new"
  post "sign-in", to: "sessions#create"
  delete "sign-out", to: "sessions#destroy"

  resource :dashboard, only: [ :show ]

  resources :assignments, only: [ :create, :show ] do
    resources :questions, only: [ :show ] do
      resource :answer, only: [ :create, :show ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#landingpage"
end
