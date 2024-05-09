Rails.application.routes.draw do
  post '/router', to: "nas_router#create"
  
mount ActionCable.server => '/cable'
get '/packages' , to: "p_poe_packages#index"
  get '/mikrotik_live', to: "mikrotik_live#mikrotik"
  # resources :accounts
  get '/pages/root'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

get "/password/reset", to: "password_resets#new"
post "/password/reset", to: "password_resets#create"


post '/create_package', to: 'p_poe_packages#create'
get '/get_package', to: 'p_poe_packages#index'
get '/create_package/:id', to: 'p_poe_packages#show'


get '/auth/auth0/callback', to: 'auth0#callback'
get '/auth/failure', to: 'auth0#failure'



delete '/package/:id',  to: 'p_poe_packages#delete'

get "/password/reset/edit", to: "password_resets#edit"
patch "password/reset/edit", to: "password_resets#update"

get "/me", to: "users#profile"
get '/csrf_token', to: 'csrf_tokens#new'


  post '/sign_in' , to: 'sessions#create'
  post '/sign_up', to: 'users#create_users' 
  delete '/logout', to: 'sessions#destroy'
end
