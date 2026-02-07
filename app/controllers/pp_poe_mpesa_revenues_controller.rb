class PpPoeMpesaRevenuesController < ApplicationController

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
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end



  # GET /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def index
    @pp_poe_mpesa_revenues = PpPoeMpesaRevenue.all
    render json: @pp_poe_mpesa_revenues
  end

  


  # POST /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def create
    @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.new(pp_poe_mpesa_revenue_params)

      if @pp_poe_mpesa_revenue.save
        render json: @pp_poe_mpesa_revenue, status: :created
      else
         render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def update
    respond_to do |format|
      if @pp_poe_mpesa_revenue.update(pp_poe_mpesa_revenue_params)
        format.html { redirect_to @pp_poe_mpesa_revenue, notice: "Pp poe mpesa revenue was successfully updated." }
        format.json { render :show, status: :ok, location: @pp_poe_mpesa_revenue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def destroy
    @pp_poe_mpesa_revenue = set_pp_poe_mpesa_revenue
    @pp_poe_mpesa_revenue.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pp_poe_mpesa_revenue
      @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pp_poe_mpesa_revenue_params
      params.require(:pp_poe_mpesa_revenue).permit(:payment_method, :amount,
       :reference, :time_paid, :account_id, :account_number,
       :payment_type
       )
    end
end
