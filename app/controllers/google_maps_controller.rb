class GoogleMapsController < ApplicationController
  before_action :set_google_map, only: %i[ show edit update destroy ]
before_action :set_time_zone
  before_action :update_last_activity
    before_action :set_tenant



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
      current_user.update!(last_activity_active: Time.now)
    end
    
  end



  # GET /google_maps or /google_maps.json
  def index
    @google_maps = GoogleMap.all
    render json: @google_maps
  end

  # GET /google_maps/1 or /google_maps/1.json
  

  # GET /google_maps/new
  def new
    @google_map = GoogleMap.new
  end

  # GET /google_maps/1/edit
  

  # POST /google_maps or /google_maps.json
  def create
    @google_map = GoogleMap.first_or_initialize(api_key: params[:api_key])
    @google_map.update(google_map_params)

      if @google_map.save
        render json: @google_map, status: :created
      else
         render json: @google_map.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /google_maps/1 or /google_maps/1.json
  def update
    respond_to do |format|
      if @google_map.update(google_map_params)
        format.html { redirect_to @google_map, notice: "Google map was successfully updated." }
        format.json { render :show, status: :ok, location: @google_map }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @google_map.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /google_maps/1 or /google_maps/1.json
  def destroy
    @google_map.destroy!

    respond_to do |format|
      format.html { redirect_to google_maps_path, status: :see_other, notice: "Google map was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_google_map
      @google_map = GoogleMap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def google_map_params
      params.require(:google_map).permit(:api_key, :account_id)
    end
end
