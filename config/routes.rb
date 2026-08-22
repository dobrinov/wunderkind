Rails.application.routes.draw do
  get "sign-up", to: "users#new"
  post "sign-up", to: "users#create"
  get "sign-in", to: "sessions#new"
  post "sign-in", to: "sessions#create"
  delete "sign-out", to: "sessions#destroy"

  get "verify-email/:token", to: "email_verifications#show", as: :verify_email
  post "verify-email", to: "email_verifications#create", as: :email_verifications
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token

  post "switch-child/:id", to: "child_sessions#create", as: :switch_child
  delete "switch-child", to: "child_sessions#destroy", as: :switch_back

  get "assignments", to: "assignments#index"
  post "assignments", to: "assignments#create"
  post "assignments/daily", to: "assignments#create_daily", as: :daily_assignment
  get "assignments/:id", to: "assignments#show", as: :assignment
  get "assignments/:id/summary", to: "assignments#summary", as: :assignment_summary
  get "questions/:id", to: "assignment_questions#show", as: :question
  get "questions/:question_id/answer", to: "answers#show", as: :question_answer
  post "questions/:question_id/answer", to: "answers#create"
  post "questions/:question_id/skip", to: "answers#skip", as: :question_skip
  post "questions/:question_id/hint", to: "hint_reveals#create", as: :question_hint_reveal
  post "questions/:question_id/report", to: "question_reports#create", as: :question_report

  resource :profile, only: [ :show, :update ] do
    post :link_code
    patch :password, to: "passwords#update"
  end

  resource :calendar, only: [ :show ] do
    get ":date/assignments", to: "assignments#index", as: :daily_assignments
  end

  resources :classrooms, only: [ :index ] do
    collection do
      post :join
    end
  end

  # The invite link. Same code as the one a teacher reads out, so a link and a
  # typed code are the same door; public, because the code is the secret.
  get "join/:code", to: "classroom_invites#show", as: :classroom_invite, constraints: { code: /[A-Za-z0-9]{4,12}/ }
  post "join/:code", to: "classroom_invites#create", constraints: { code: /[A-Za-z0-9]{4,12}/ }

  resources :challenges, only: [ :index, :create, :show, :destroy ] do
    member do
      get :state
    end
    resources :answers, only: [ :create ], controller: "challenge_answers"
    resources :reports, only: [ :create ], controller: "challenge_reports"
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
    resources :question_reports, only: [ :index ], param: :question_id do
      member do
        post :resolve
        post :dismiss
        post :withdraw
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
