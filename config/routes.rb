Rails.application.routes.draw do
 

mount ActionCable.server => '/cable'

post '/zone', to: "zones#create"
get '/zones', to: 'zones#index'
patch '/update_zone/:id', to: 'zones#update'

post '/router', to: "nas_routers#create"
get '/routers', to: 'nas_routers#index' 
delete '/delete_router/:id', to: 'nas_routers#delete'
get '/packages' , to: "packages#index"
  get '/mikrotik_live', to: "mikrotik_live#mikrotik"

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

get "/password/reset", to: "password_resets#new"
post "/password/reset", to: "password_resets#create"


post '/create_package', to: 'packages#create'
get '/get_package', to: 'packages#index'
get '/create_package/:id', to: 'packages#show'


get '/auth/auth0/callback', to: 'auth0#callback'
get '/auth/failure', to: 'auth0#failure'
patch '/update_package/:id', to: 'packages#update_package'
delete '/package/:id',  to: 'packages#delete'

get "/password/reset/edit", to: "password_resets#edit"
patch "password/reset/edit", to: "password_resets#update"

get "/me", to: "users#profile"
get '/csrf_token', to: 'csrf_tokens#new'


  post '/sign_in' , to: 'sessions#create'
  post '/sign_up', to: 'users#create_users' 
  delete '/logout', to: 'sessions#destroy'
end
