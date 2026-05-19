Rails.application.routes.draw do
  get  "blockchain/verify", to: "blockchain#verify"
  post "messages", to: "messages#create"
  get "messages/:id/verify", to: "messages#verify"

  get "messages/:user_id", to: "messages#index"
  get "group_messages/:group_id", to: "messages#group_index"
  post "groups", to: "groups#create"
  get "groups", to: "groups#index"
  get "groups/:id/members", to: "groups#members"
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"
  get "users", to: "users#index"
  get "users/:id/key", to: "users#key"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: redirect("/login.html")
end

