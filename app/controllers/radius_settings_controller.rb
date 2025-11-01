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
     ActsAsTenant.current_tenant = @account
    # EmailConfiguration.configure(@current_account)
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])

  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end




  # def index
  #   @nas = Na.all

  #   if @nas.nasname.blanl?
  #     default_nas_name = Na.first_or_initialize(
  #       nasname: ActsAsTenant.current_tenant.
  #     )

  #   end


  #   render json: @nas, each_serializer: NasSerializer
  # end

def index
@nas = Na.all
render json: @nas, each_serializer: NasSerializer
end



  def create_nas_settings

        
        
          @nas = Na.find_or_initialize_by(nasname: params[:ip] )



@nas.update!(
shortname: 'admin', secret: params[:shared_secret]
)


if @nas.save
  ActivtyLog.create(action: 'configuration', ip: request.remote_ip,
 description: "Configured NAS settings #{@nas.shortname}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
  render json: @nas
else
  
  render json: {error: "Error creating NAS settings"}, status: :unprocessable_entity
end
        end
    
  




  
end
