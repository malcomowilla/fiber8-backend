class PartnersController < ApplicationController


  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone






  def set_time_zone
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

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




  # GET /partners or /partners.json
  def index
    @partners = Partner.all
    render json: @partners
  end

  # GET /partners/1 or /partners/1.json
  def show
  end

  # GET /partners/new
  def new
    @partner = Partner.new
  end

  # GET /partners/1/edit
  def edit
  end

  # POST /partners or /partners.json
  def create
    @partner = Partner.new(partner_params)

      if @partner.save
        render json: @partner, status: :created
      else
      render json: @partner.errors, status: :unprocessable_entity 
      end
  end

  # PATCH/PUT /partners/1 or /partners/1.json
  def update
    @partner = set_partner
      if @partner.update(partner_params)
        render json: @partner, status: :ok
      else
      render json: @partner.errors, status: :unprocessable_entity 
      end
  end

  # DELETE /partners/1 or /partners/1.json
  def destroy
    @partner = set_partner
    @partner.destroy!

       head :no_content 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_partner
      @partner = Partner.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def partner_params
      params.require(:partner).permit(:full_name, :partner_type,
       :status, :email, :phone, :city, :country, :notes, :commission_type, 
       :commission_rate, :fixed_amount, :minimum_payout,
        :payout_method, :payout_frequency, :mpesa_number, 
        :mpesa_name, :bank_name, :account_number,
         :account_name, :status, :account_id)
    end
end
