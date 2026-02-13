class HotspotCustomizationsController < ApplicationController


  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
    before_action :set_time_zone




    def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

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





def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end




  # GET /hotspot_customizations or /hotspot_customizations.json
  def index
    @hotspot_customizations = HotspotCustomization.all
    render json: @hotspot_customizations
  end



  def allow_get_hotspot_customization
 @hotspot_customizations = HotspotCustomization.all
    render json: @hotspot_customizations
  end

  # GET /hotspot_customizations/1 or /hotspot_customizations/1.json
 

  # POST /hotspot_customizations or /hotspot_customizations.json
  def create
    @hotspot_customization = HotspotCustomization.first_or_initialize(
      customize_template_and_package_per_location: params[:customize_template_and_package_per_location],
      enable_autologin: params[:enable_autologin]
      
      )
      @hotspot_customization.update(
        customize_template_and_package_per_location: params[:customize_template_and_package_per_location],
        enable_autologin: params[:enable_autologin]
        
        )

      if @hotspot_customization.save
         render json: @hotspot_customization, status: :created
      else
         render json: @hotspot_customization.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /hotspot_customizations/1 or /hotspot_customizations/1.json
  def update
    respond_to do |format|
      if @hotspot_customization.update(hotspot_customization_params)
        format.html { redirect_to @hotspot_customization, notice: "Hotspot customization was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_customization }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_customization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_customizations/1 or /hotspot_customizations/1.json
  def destroy
    @hotspot_customization.destroy!

    respond_to do |format|
      format.html { redirect_to hotspot_customizations_path, status: :see_other, notice: "Hotspot customization was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_customization
      @hotspot_customization = HotspotCustomization.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_customization_params
      params.require(:hotspot_customization).permit(:customize_template_and_package_per_location,
      :enable_autologin,
       :account_id)
    end
end








