class RadiusSettingsController < ApplicationController


  # load_and_authorize_resource
  load_and_authorize_resource class: 'Na'

  set_current_tenant_through_filter
  before_action :set_tenant
    before_action :update_last_activity








   def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account= ActsAsTenant.current_tenant 
    # EmailConfiguration.configure(@current_account)
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])

  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end




  def index
    
    @nas = Na.all
    render json: @nas, each_serializer: NasSerializer
  end



  def create_nas_settings
        host = request.headers['X-Subdomain']

         if host == 'demo'
          render json: {error: "Demo tenant does not allow NAS
           settings creation"}, status: :unprocessable_entity
        else
          @nas = Na.first_or_initialize(shortname: params[:shortname], 
    nasname: params[:ipaddr], secret: params[:secret] )

@nas.update(
 shortname: params[:shortname], 
    nasname: params[:ipaddr], secret: params[:secret]
)


if @nas.save
  render json: @nas
else
  
  render json: {error: "Error creating NAS settings"}, status: :unprocessable_entity
end
        end
    
  end




  
end
