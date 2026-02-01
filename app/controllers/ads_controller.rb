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
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


  def number_of_ads
    @number_of_ads = Ad.count
     render json: @number_of_ads
  end



def total_ad_clicks

  @count = AnalyticsEvent.where(event_type: 'click').count
   render json: @count
  
end



def total_ad_impressions

  @count = AnalyticsEvent.where(event_type: 'Ad View').count
   render json: @count
end


  def track_ad_event

 data = {
    event_type: params[:event_type],
    button_name: params[:button_name],
    timestamp: Time.current.to_s,
    account_id: ActsAsTenant.current_tenant.id,
  }.to_json

  $redis.rpush("analytics_events", data) 
  render json: { message: 'Event Tracked' }, status: :ok
    
  end






  # GET /ads or /ads.json
  def index
    @ads = Ad.all
    render json: @ads 
  end

  # GET /ads/1 or /ads/1.json
  def show
  end

  # GET /ads/new
  def new
    @ad = Ad.new
  end

  # GET /ads/1/edit
  def edit
  end

  # POST /ads or /ads.json
  def create
    @ad = Ad.first_or_initialize(
title: params[:title],
description: params[:description],
business_name: params[:business_name],
business_type: params[:business_type],
offer_text: params[:offer_text],
discount: params[:discount],
cat_text: params[:cat_text],
background_color: params[:background_color],
text_color: params[:text_color],
image: params[:image],
imagePreview: params[:imagePreview],
target_url: params[:target_url],
image_preview: params[:image_preview],
website: params[:contact][:website],
phone: params[:contact][:phone],
email: params[:contact][:email],
)

    @ad.update(
  title: params[:title],
description: params[:description],
business_name: params[:business_name],
business_type: params[:business_type],
offer_text: params[:offer_text],
discount: params[:discount],
cat_text: params[:cat_text],
background_color: params[:background_color],
text_color: params[:text_color],
image: params[:image],
imagePreview: params[:imagePreview],
target_url: params[:target_url],
image_preview: params[:image_preview],
website: params[:contact][:website],
phone: params[:contact][:phone],
email: params[:contact][:email],
    )

      if @ad.save
       render json: @ad, status: :created
      else
         render json: @ad.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /ads/1 or /ads/1.json
  def update
      if @ad.update(ad_params)
        render json: @ad, status: :ok
      else
        render json: @ad.errors, status: :unprocessable_entity 
      
    end
  end

  # DELETE /ads/1 or /ads/1.json
  def destroy
    @ad.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ad
      @ad = Ad.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ad_params
      params.require(:ad).permit(:title, :description, :business_name, :business_type, 
      :offer_text, :discount, :cat_text, :background_color, :text_color, :image,
       :imagePreview, :target_url, :is_active,  :image_preview)
    end
end
