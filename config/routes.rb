Rails.application.routes.draw do
  get "canvas", to: "static_pages#canvas"

  resources :assignments, only: [ :create, :show ] do
    resources :questions, only: [ :show ] do
      resource :answer, only: [ :create, :show ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "static_pages#landingpage"
end
