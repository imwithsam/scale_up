Rails.application.routes.draw do

  get 'errors/not_found'

  get 'errors/internal_server_error'

  root "home#index"

  get "/browse", to: "loan_requests#index"

  get "/portfolio", to: "borrower_portfolio#show"

  resources :payment, only: [:update]

  resources :loan_requests

  get "/cart", to: "cart#index"
  post "/cart", to: "cart#create"
  delete "/cart", to: "cart#delete"
  put "/cart", to: "cart#update"

  resources :orders, only: [:create, :index, :show, :update]

  get "/login", to: "sessions#new", :as => "login"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"
  delete "/logout", to: "sessions#destroy"

  resources :lenders

  resources :borrowers

  resources :users, only: [:show]

  get "/404" => "errors#not_found"
  get "/500" => "errors#internal_server_error"

  get "*path", to: "home#not_found"
end
