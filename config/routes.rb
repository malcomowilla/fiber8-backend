Rails.application.routes.draw do
  resources :router_settings
  resources :hotspot_packages
 
  # kaorizebabnon$5%
  # kaori
  # kaori12

  # cp ./master_key/master.key /hfiber8-backend/config

mount ActionCable.server => '/cable'

get '/get_general_settings', to: "subscribers#get_general_settings"
get '/subscribers', to: "subscribers#index"
post '/subscriber', to: "subscribers#create"
patch '/update_subscriber/:id', to: 'subscribers#update'
delete '/delete_subscriber/:id', to: 'subscribers#delete'
post '/update_general_settings', to: "subscribers#update_general_settings"
patch 'update_hotspot_package/:id', to: 'hotspot_packages#update'
delete 'delete_hotspot_package/:id', to: 'hotspot_packages#delete'

post '/zone', to: "zones#create"
get '/zones', to: 'zones#index'
patch '/update_zone/:id', to: 'zones#update'
delete '/delete_zone/:id', to: 'zones#delete'

post '/create_router', to: "nas_routers#create"

patch '/update_router/:id', to: "nas_routers#update"
get '/routers', to: 'nas_routers#index' 
delete '/delete_router/:id', to: 'nas_routers#delete'


  get '/mikrotik_live', to: "mikrotik_live#mikrotik"

  # get "up" => "rails/health#show", as: :rails_health_check
  get '/up', to: 'health#up'
  # Defines the root path route ("/")
  # root "posts#index"

get "/password/reset", to: "password_resets#new"
post "/password/reset", to: "password_resets#create"

get '/auth/auth0/callback', to: 'auth0#callback'
get '/auth/failure', to: 'auth0#failure'


get '/packages' , to: "packages#index"
post '/create_package', to: 'packages#create'
get '/get_package', to: 'packages#index'
get '/create_package/:id', to: 'packages#show'
patch '/update_package/:id', to: 'packages#update_package'
delete '/package/:id',  to: 'packages#delete'


get '/csrf_token', to: 'csrf_tokens#new'


get "/me", to: "users#profile"
get '/get_passkey_credentials', to: 'sessions#get_passkey_credentials'

post '/update_profile', to: "sessions#update_admin"
get "/password/reset/edit", to: "password_resets#edit"
patch "password/reset/edit", to: "password_resets#update"
  post '/sign_in' , to: 'sessions#create'
  post '/sign_up', to: 'users#create_users' 
  delete '/logout', to: 'sessions#destroy'
  post '/webauthn/authenticate', to: 'sessions#authenticate_webauthn'
  post '/webauthn/verify', to: 'sessions#verify_webauthn'


post '/webauthn/register', to: 'sessions#register_webauthn'

post '/webauthn/create', to: 'sessions#create_webauthn'
delete '/delete_passkey', to: 'sessions#delete_webauthn'

  
  get '/currently_logged_in_user', to: 'sessions#currently_logged_in_user'
end
