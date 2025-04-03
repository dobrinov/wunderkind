Rails.application.routes.draw do
  root "static_pages#landingpage"
  get "static_pages/landingpage"

  # Question session routes
  get 'questions/start', to: 'questions#start', as: :questions_start
  get 'questions', to: 'questions#show', as: :question
  post 'questions/answer', to: 'questions#answer', as: :questions_answer
  get 'questions/feedback', to: 'questions#feedback', as: :feedback
  get 'questions/results', to: 'questions#results', as: :results

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
