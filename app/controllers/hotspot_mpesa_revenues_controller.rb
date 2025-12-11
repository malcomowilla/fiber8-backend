class HotspotMpesaRevenuesController < ApplicationController
  # before_action :set_hotspot_mpesa_revenue, only: %i[ show edit update destroy ]


  set_current_tenant_through_filter


  
  before_action :set_tenant
  # GET /hotspot_mpesa_settings or /hotspot_mpesa_settings.json
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



  # GET /hotspot_mpesa_revenues or /hotspot_mpesa_revenues.json
  def index
    @hotspot_mpesa_revenues = HotspotMpesaRevenue.all
    render json: @hotspot_mpesa_revenues
  end

 
 

  # POST /hotspot_mpesa_revenues or /hotspot_mpesa_revenues.json
  def create
    @hotspot_mpesa_revenue = HotspotMpesaRevenue.new(hotspot_mpesa_revenue_params)

    respond_to do |format|
      if @hotspot_mpesa_revenue.save
        format.html { redirect_to @hotspot_mpesa_revenue, notice: "Hotspot mpesa revenue was successfully created." }
        format.json { render :show, status: :created, location: @hotspot_mpesa_revenue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @hotspot_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hotspot_mpesa_revenues/1 or /hotspot_mpesa_revenues/1.json
  def update
    respond_to do |format|
      if @hotspot_mpesa_revenue.update(hotspot_mpesa_revenue_params)
        format.html { redirect_to @hotspot_mpesa_revenue, notice: "Hotspot mpesa revenue was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_mpesa_revenue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_mpesa_revenues/1 or /hotspot_mpesa_revenues/1.json
  def destroy
    @hotspot_mpesa_revenue.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_mpesa_revenue
      @hotspot_mpesa_revenue = HotspotMpesaRevenue.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_mpesa_revenue_params
      params.require(:hotspot_mpesa_revenue).permit(:voucher, :payment_method, :amount,
       :reference, :time_paid, :account_id)
    end
end


