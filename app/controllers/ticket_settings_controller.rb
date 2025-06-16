class TicketSettingsController < ApplicationController


  set_current_tenant_through_filter

  before_action :set_tenant
  load_and_authorize_resource
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
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end




  def show

    @ticket_settings = TicketSetting.all
    render json: @ticket_settings
  end



  def create
    @ticket_settings = TicketSetting.first_or_initialize(
    prefix: params[:prefix],
    minimum_digits: params[:minimum_digits]
    )
    @ticket_settings.update(
      prefix: params[:prefix],
      minimum_digits: params[:minimum_digits]
    )

    
    if @ticket_settings.save
      render json: @ticket_settings, status: :created
    else
      render json: @ticket_settings.errors, status: :unprocessable_entity
    end
  end

  def allow_get_ticket_settings
    @ticket_settings = TicketSetting.all
    render json: @ticket_settings
  end


private
def ticket_setting_params
    params.permit(:prefix, :minimum_digits)
  end


end