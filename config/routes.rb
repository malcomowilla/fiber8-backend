Rails.application.routes.draw do
  resources :license_settings
  resources :ip_networks
  resources :nodes
  resources :sms_provider_settings
  resources :user_groups
  resources :dial_up_mpesa_settings
  resources :hotspot_mpesa_settings
  # resources :hotspot_plans
  # resources :pp_poe_plans
  resources :isp_subscriptions
  resources :hotspot_settings
  resources :sms_templates
  resources :hotspot_subscriptions
  get "add_user_profile_id_and_user_id_to_hotspot_vouchers/user_manager_user_id"
  get "add_user_profile_id_and_user_id_to_hotspot_vouchers/user_profile_id"
  resources :hotspot_vouchers
  resources :hotspot_templates
  resources :admin_settings
 
  resources :ip_pools
  resources :subscriber_settings
  resources :support_tickets
  resources :sms_settings
  resources :subscriptions

  # resources :sms
  resources :system_admin_web_authn_credentials
  resources :email_settings
  resources :system_admin_email_settings
  resources :system_admin_sms
  resources :system_admins
  resources :company_settings
  resources :router_settings
  resources :hotspot_packages
  resource :ticket_settings
  # resources :pppoe_plans
  # resources :hotspot_plans


  # namespace :api do
  #   resources :pppoe_plans, only: [:index, :create, :update]
  #   resources :hotspot_plans, only: [:index, :create, :update]
  # end
  # allow_get_admin_settings
 
mount ActionCable.server => '/cable'
scope '/api' do
  resources :license_settings

  resources :ip_pools
  resources :user_groups
  resources :ip_networks
  resources :subscriptions
  resources :sms_provider_settings                                   
  resources :dial_up_mpesa_settings
  resources :hotspot_mpesa_settings
  resources :sms_templates
  resources :support_tickets
  resource :ticket_settings
  resources :subscriber_settings
  resources :email_settings
  resources :hotspot_packages
  resources :sms_settings
  resources :admin_settings
  resources :hotspot_templates
  resources :hotspot_vouchers
  resources :hotspot_settings
  resources :hotspot_subscriptions
  # resources :pp_poe_plans
  # resources :hotspot_plans
  resources :system_admin_sms
  # resources :pppoe_plans
  # resources :hotspot_plans




end


get '/get_ips', to: 'subscriptions#get_ips'
patch '/api/pppoe_plans', to: 'pp_poe_plans#update'
get '/api/pppoe_plans', to: 'pp_poe_plans#index'
get '/pppoe_plans', to: 'pp_poe_plans#index'
get '/get_current_pppoe_plan', to: 'pp_poe_plans#get_current_plan'
get '/api/get_current_pppoe_plan', to: 'pp_poe_plans#get_current_plan'
get '/api/allow_get_current_pppoe_plan', to: 'pp_poe_plans#allow_get_current_plan'
get '/allow_get_current_pppoe_plan', to: 'pp_poe_plans#allow_get_current_plan'

get '/get_current_hotspot_plan', to: 'hotspot_plans#get_current_hotspot_plan'
get '/api/get_current_hotspot_plan', to: 'hotspot_plans#get_current_hotspot_plan'
get '/api/allow_get_current_hotspot_plan', to: 'hotspot_plans#allow_get_current_hotspot_plan'
get '/allow_get_current_hotspot_plan', to: 'hotspot_plans#allow_get_current_hotspot_plan'


get '/api/hotspot_plans', to: 'hotspot_plans#index'
get '/hotspot_plans', to: 'hotspot_plans#index'


patch '/pppoe_plans', to: 'pppoe_plans#update'
post '/api/pppoe_plans/', to: 'pppoe_plans#create'
post '/api/hotspot_plans/', to: 'hotspot_plans#create'
post '/hotspot_plans/', to: 'hotspot_plans#create'

post '/pppoe_plans/', to: 'pppoe_plans#create'


get '/api/get_ips', to: 'subscriptions#get_ips'
get '/api/last_seen', to: 'subscriptions#last_seen'
get '/last_seen', to: 'subscriptions#last_seen'
post '/api/block_service', to: 'subscriptions#block_service'
post '/block_service', to: 'subscriptions#block_service'
get '/api/pppoe_stats', to: 'subscriptions#pppoe_stats'
get '/pppoe_stats', to: 'subscriptions#pppoe_stats'
post '/api/send_sms', to: 'send_sms#send_sms'
post '/api/reboot_router', to: 'system_metrics#reboot_router'
post '/reboot_router', to: 'system_metrics#reboot_router'
get '/api/wireguard/generate_config', to: 'wireguard#generate_config'
post '/api/wireguard/generate_config', to: 'wireguard#generate_config'
post '/wireguard/generate_config', to: 'wireguard#generate_config'



get '/wireguard/generate_config', to: 'wireguard#generate_config'
  get '/api/service_status', to: 'system_metrics#check_services'
  get '/service_status', to: 'system_metrics#check_services'
  
  post '/restart_service', to: 'system_metrics#restart_service'
  post '/api/restart_service', to: 'system_metrics#restart_service'

post '/api/radius_settings', to: 'radius_settings#create_nas_settings'
post '/radius_settings', to: 'radius_settings#create_nas_settings'

get '/radius_settings', to: 'radius_settings#index'
get '/api/radius_settings', to: 'radius_settings#index'


get '/api/system_status', to: 'system_metrics#system_status'
get '/system_status', to: 'system_metrics#system_status'


post '/api/mpesa/', to: 'hotspot_mpesa_settings#customer_mpesa_stk_payments'
post '/mpesa/', to: 'hotspot_mpesa_settings#customer_mpesa_stk_payments'

post '/customer_mpesa_stk_payments', to: 'hotspot_mpesa_settings#customer_mpesa_stk_payments'
post '/api/customer_mpesa_stk_payments', to: 'hotspot_mpesa_settings#customer_mpesa_stk_payments'
# get '/api/allow_get_hotspot_setting', to: 'hotspot_settings#allow_get_hotspot_setting'
# get '/allow_get_hotspot_setting', to: 'hotspot_settings#allow_get_hotspot_setting'
get '/api/saved_hotspot_mpesa_settings', to: 'hotspot_mpesa_settings#saved_hotspot_mpesa_settings'
get '/saved_hotspot_mpesa_settings', to: 'hotspot_mpesa_settings#saved_hotspot_mpesa_settings'
get '/api/current_plan', to: 'system_admins#current_plan'
get '/current_plan', to: 'system_admins#current_plan'
get '/api/current_hotspot_plan', to: 'system_admins#current_hotspot_plan'
get '/current_hotspot_plan', to: 'system_admins#current_hotspot_plan'
 

patch '/api/update_client/:id', to: 'system_admins#update_client'
patch '/update_client/:id', to: 'system_admins#update_client'


post '/api/make_payment', to: 'hotspot_vouchers#make_payment'
post '/make_payment', to: 'hotspot_vouchers#make_payment'

get '/api/expired_vouchers', to: 'hotspot_vouchers#expired_vouchers'
get '/expired_vouchers', to: 'hotspot_vouchers#expired_vouchers'

get '/api/active_vouchers', to: 'hotspot_vouchers#active_vouchers'
get '/active_vouchers', to: 'hotspot_vouchers#active_vouchers'

get '/total_subscribers', to: 'subscribers#total_subscribers'
get '/api/total_subscribers', to: 'subscribers#total_subscribers'

get '/api/saved_sms_settings', to: 'sms_settings#saved_sms_settings'
get '/saved_sms_settings', to: 'sms_settings#saved_sms_settings'


get '/get_hotspot_settings', to: 'hotspot_settings#get_hotspot_setting'
get '/api/get_hotspot_settings', to: 'hotspot_settings#get_hotspot_setting'
get '/api/allow_get_hotspot_packages', to: 'hotspot_packages#allow_get_hotspot_packages'
get '/allow_get_hotspot_packages', to: 'hotspot_packages#allow_get_hotspot_packages'


get '/get_active_hotspot_users', to: 'hotspot_subscriptions#get_active_hotspot_users'

get '/api/get_active_hotspot_users', to: 'hotspot_subscriptions#get_active_hotspot_users'
get '/allow_get_hotspot_templates', to: 'hotspot_templates#allow_get_hotspot_templates'
get '/api/allow_get_hotspot_templates', to: 'hotspot_templates#allow_get_hotspot_templates'

get '/api/router_info', to: 'router_info#router_info'
post '/login_with_hotspot_voucher', to: 'hotspot_vouchers#login_with_hotspot_voucher'
post '/api/login_with_hotspot_voucher', to: 'hotspot_vouchers#login_with_hotspot_voucher'


get '/router_info', to: 'router_info#router_info'
delete '/api/delete_user/:id', to: 'user_invite#delete_user'
delete '/delete_user/:id', to: 'user_invite#delete_user'

get '/get_all_admins', to: 'user_invite#get_all_admins'
get '/api/get_all_admins', to: 'user_invite#get_all_admins'
post '/invite_client', to: 'user_invite#invite_users'
patch '/update_user_admins/:id', to: 'user_invite#update'
patch '/api/update_user_admins/:id', to: 'user_invite#update'

patch '/api/update_client/:id', to: 'user_invite#update'

post '/api/invite_client', to: 'user_invite#invite_users'
get '/api/allow_get_admin_settings', to: 'admin_settings#allow_get_admin_settings'
get '/allow_get_admin_settings', to: 'admin_settings#allow_get_admin_settings'
get '/get_all_clients', to: 'accounts#index'
get '/api/get_all_clients', to: 'accounts#index'
patch '/api/update_ticket/:id', to: 'support_tickets#update'
patch '/update_ticket/:id', to: 'support_tickets#update'
post '/api/create_ticket', to: 'support_tickets#create'
post '/create_ticket', to: 'support_tickets#create'
get '/api/get_tickets', to: 'support_tickets#index'
get '/get_tickets', to: 'support_tickets#index'
get '/api/allow_get_ticket_settings', to: 'ticket_settings#allow_get_ticket_settings'
get '/allow_get_ticket_settings', to: 'ticket_settings#allow_get_ticket_settings'
get '/get_sms_balance', to: 'sms#get_the_sms_balance'
get '/api/get_sms_balance', to: 'sms#get_the_sms_balance'
get '/api/router_settings', to: 'router_settings#index'
post '/api/router_settings', to: 'router_settings#create'
post '/router_settings', to: 'router_settings#create'
get '/api/allow_get_router_settings', to: 'router_settings#allow_get_router_settings'
get '/allow_get_router_settings', to: 'router_settings#allow_get_router_settings'
get '/get_general_settings', to: "subscribers#get_general_settings"
get '/api/get_general_settings', to: "subscribers#get_general_settings"
get '/subscribers', to: "subscribers#index"
post '/api/subscribers/import', to: "subscribers#import"
post '/subscribers/import', to: "subscribers#import"
get '/api/subscribers', to: "subscribers#index"
post '/subscriber', to: "subscribers#create"
post '/api/subscriber', to: "subscribers#create"
patch '/update_subscriber/:id', to: 'subscribers#update'
patch '/api/update_subscriber/:id', to: 'subscribers#update'
delete '/delete_subscriber/:id', to: 'subscribers#delete'
delete '/api/delete_subscriber/:id', to: 'subscribers#delete'
post '/update_general_settings', to: "subscribers#update_general_settings"
post '/api/update_general_settings', to: "subscribers#update_general_settings"
patch 'update_hotspot_package/:id', to: 'hotspot_packages#update'
patch '/api/update_hotspot_package/:id', to: 'hotspot_packages#update'
delete 'delete_hotspot_package/:id', to: 'hotspot_packages#delete'
delete '/api/delete_hotspot_package/:id', to: 'hotspot_packages#delete'

get '/current_system_admin', to: 'system_admins#current_system_admin_controller_of_networks'
get '/api/current_system_admin', to: 'system_admins#current_system_admin_controller_of_networks'
get '/get_system_admin_settings', to: 'system_admins#get_system_admin_settings'
get '/api/get_system_admin_settings', to: 'system_admins#get_system_admin_settings'
post '/create_system_admin_settings', to: 'system_admins#create_system_admin_settings'
post '/api/create_system_admin_settings', to: 'system_admins#create_system_admin_settings'
post '/webauthn/verify-system-admin', to: 'system_admins#verify_webauthn_system_admin'
post '/api/webauthn/verify-system-admin', to: 'system_admins#verify_webauthn_system_admin'
post '/webauthn/register_system_admin', to: 'system_admins#register_webauthn_system_admin'
post '/api/webauthn/register_system_admin', to: 'system_admins#register_webauthn_system_admin'


post '/otp-verification', to: 'system_admins#verify_otp'
post '/api/otp-verification', to: 'system_admins#verify_otp'
post '/system-admin-login', to: 'system_admins#login'
post '/api/system-admin-login', to: 'system_admins#login'
get '/phone_number_verified', to: 'system_admins#check_sms_already_verified'
post '/verify_otp_email', to: 'system_admins#verify_otp_email'
post '/api/verify_otp_email', to: 'system_admins#verify_otp_email'
get '/email_verified', to: 'system_admins#check_email_already_verified'
get '/api/email_verified', to: 'system_admins#check_email_already_verified'
get '/api/phone_number_verified', to: 'system_admins#check_sms_already_verified'
delete '/logout_system_admin', to: 'system_admins#logout'
delete '/api/logout_system_admin', to: 'system_admins#logout'

post '/webauthn/register_webauthn_system_admin', to: 'system_admins#register_webauthn_system_admin'
post '/api/webauthn/register_webauthn_system_admin', to: 'system_admins#register_webauthn_system_admin'

post '/webauthn/create_webauthn_system_admin', to: 'system_admins#create_webauthn_system_admin'
post '/api/webauthn/create_webauthn_system_admin', to: 'system_admins#create_webauthn_system_admin'
post '/webauthn/authenticate_webauthn_login_system_admin', to: 'system_admins#authenticate_webauthn_login_system_admin'
post '/api/webauthn/authenticate_webauthn_login_system_admin', to: 'system_admins#authenticate_webauthn_login_system_admin'
post '/webauthn/verify_webauthn_login_system_admin', to: 'system_admins#verify_webauthn_login_system_admin'
post '/api/webauthn/verify_webauthn_login_system_admin', to: 'system_admins#verify_webauthn_login_system_admin'

post '/invite_client_super_admins', to: 'system_admins#invite_company_super_admins'
post '/api/invite_client_super_admins', to: 'system_admins#invite_company_super_admins'

get '/api/get_passkey_credentials_system_admin', to: 'system_admins#get_passkey_credentials_system_admin'

get '/get_passkey_credentials_system_admin', to: 'system_admins#get_passkey_credentials_system_admin'

post '/zone', to: "zones#create"
post '/api/zone', to: "zones#create"
get '/zones', to: 'zones#index'
get '/api/zones', to: 'zones#index'
patch '/update_zone/:id', to: 'zones#update'
patch '/api/update_zone/:id', to: 'zones#update'
delete '/delete_zone/:id', to: 'zones#delete'

delete '/api/delete_zone/:id', to: 'zones#delete'


post '/create_router', to: "nas_routers#create"
post '/api/create_router', to: "nas_routers#create"

get '/router_ping_response', to: 'nas_routers#router_ping_response'
get '/api/router_ping_response', to: 'nas_routers#router_ping_response'


patch '/update_router/:id', to: "nas_routers#update"
patch '/api/update_router/:id', to: "nas_routers#update"
get '/routers', to: 'nas_routers#index' 
get '/api/routers', to: 'nas_routers#index'
delete '/delete_router/:id', to: 'nas_routers#delete'
delete '/api/delete_router/:id', to: 'nas_routers#delete'

post '/company_settings', to: 'company_settings#create'
post '/api/company_settings', to: 'company_settings#create'
get '/get_company_settings', to: 'company_settings#index'
get '/api/get_company_settings', to: 'company_settings#index'
get '/allow_get_company_settings', to: 'company_settings#allow_get_company_settings'
get '/api/allow_get_company_settings', to: 'company_settings#allow_get_company_settings'

post '/hotspot_trial', to: 'hotspot_trial#create'
post '/api/hotspot_trial', to: 'hotspot_trial#create'


  get '/mikrotik_live', to: "mikrotik_live#mikrotik"
  get '/api/mikrotik_live', to: "mikrotik_live#mikrotik"

  # get "up" => "rails/health#show", as: :rails_health_check
  get '/up', to: 'health#up'
  # Defines the root path route ("/")
  # root "posts#index"

post "/password_reset", to: "password_resets#reset_password_confirmation"
post "/api/password_reset", to: "password_resets#reset_password_confirmation"
post "/password/reset", to: "password_resets#create"
post "/api/password/reset", to: "password_resets#create"


get '/auth/auth0/callback', to: 'auth0#callback'
get '/auth/failure', to: 'auth0#failure'


get '/api/allow_get_packages' , to: "packages#allow_get_packages"
get '/allow_get_packages' , to: "packages#allow_get_packages"

get '/packages' , to: "packages#index"
get '/api/packages' , to: "packages#index"
post '/create_package', to: 'packages#create'
post '/api/create_package', to: 'packages#create'
get '/get_package', to: 'packages#index'
get '/api/get_package', to: 'packages#index'
get '/create_package/:id', to: 'packages#show'
get '/api/create_package/:id', to: 'packages#show'
patch '/update_package/:id', to: 'packages#update_package'
patch '/api/update_package/:id', to: 'packages#update_package'
delete '/package/:id',  to: 'packages#delete'
delete '/api/package/:id',  to: 'packages#delete'



get '/csrf_token', to: 'csrf_tokens#new'


get "/me", to: "users#profile"
get "/api/me", to: "users#profile"
get '/get_passkey_credentials', to: 'sessions#get_passkey_credentials'
get '/api/get_passkey_credentials', to: 'sessions#get_passkey_credentials'


post '/update_profile', to: "sessions#update_admin"
post '/api/update_profile', to: "sessions#update_admin"
get "/password/reset/edit", to: "password_resets#edit"
get "/api/password/reset/edit", to: "password_resets#edit"
patch "password/reset/edit", to: "password_resets#update"
patch "/api/password/reset/edit", to: "password_resets#update"
  post '/api/sign_in' , to: 'sessions#create'
  post '/sign_in' , to: 'sessions#create'

  post '/api/sign_up', to: 'users#create_users' 
  delete '/api/logout', to: 'sessions#destroy'
  delete '/api/logout', to: 'sessions#destroy'
  delete '/logout', to: 'sessions#destroy'
  delete '/api/logout', to: 'sessions#destroy'

  post '/webauthn/authenticate', to: 'sessions#authenticate_webauthn'
  post '/api/webauthn/authenticate', to: 'sessions#authenticate_webauthn'
  post '/webauthn/verify', to: 'sessions#verify_webauthn'
  post '/api/webauthn/verify', to: 'sessions#verify_webauthn'


post '/webauthn/register', to: 'sessions#register_webauthn'
post '/api/webauthn/register', to: 'sessions#register_webauthn'

post '/webauthn/create', to: 'sessions#create_webauthn'
post '/api/webauthn/create', to: 'sessions#create_webauthn'
delete '/delete_passkey', to: 'sessions#delete_webauthn'
delete '/api/delete_passkey', to: 'sessions#delete_webauthn'


  
  get '/currently_logged_in_user', to: 'sessions#currently_logged_in_user'
  get '/api/currently_logged_in_user', to: 'sessions#currently_logged_in_user'








#   {
#   "address": "any",
#   "arp-ping": "any",
#   "as-value": "any",
#   "count": "any",
#   "do-not-fragment": "any",
#   "dscp": "any",
#   "interface": "any",
#   "interval": "any",
#   "size": "any",
#   "src-address": "any",
#   "ttl": "any",
#   "vrf": "any",
#   "without-paging": "any",
#   ".proplist": "any",
#   ".query": "array"
# }




end
