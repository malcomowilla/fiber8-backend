class AdsController < ApplicationController

  set_current_tenant_through_filter
  before_action :set_tenant
    before_action :update_last_activity


    before_action :set_time_zone




    def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end



     def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end

def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    # EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


 def number_of_ads
  render json: AdSetting.where(account_id: @account.id).count
end

def total_ad_clicks
  ad_id = params[:ad_id]
  scope = AnalyticsEvent.where(event_type: 'click', account_id: @account.id)
  scope = scope.where(ad_setting_id: ad_id) if ad_id.present?
  render json: scope.count
end

def total_ad_impressions
  ad_id = params[:ad_id]
  scope = AnalyticsEvent.where(event_type: 'Ad View', account_id: @account.id)
  scope = scope.where(ad_setting_id: ad_id) if ad_id.present?
  render json: scope.count
end

def track_ad_event
  data = {
    event_type: params[:event_type],
    button_name: params[:button_name],
    ad_setting_id: params[:ad_id],
    timestamp: Time.current.to_s,
    account_id: ActsAsTenant.current_tenant.id,
  }.to_json

  $redis.rpush("analytics_events", data)
  render json: { message: 'Event Tracked' }, status: :ok
end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ad
      @ad = Ad.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
   
end
