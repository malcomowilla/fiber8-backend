class CompanyFinancialRecordsController < ApplicationController




  load_and_authorize_resource

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
      current_user.update!(last_activity_active: Time.now)
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




  # GET /company_financial_records or /company_financial_records.json
  def index
    @company_financial_records = CompanyFinancialRecord.all
    render json: @company_financial_records
  end




  # GET /company_financial_records/1 or /company_financial_records/1.json
  
  # GET /company_financial_records/new
  def new
    @company_financial_record = CompanyFinancialRecord.new
  end

  # GET /company_financial_records/1/edit
  def edit
  end

  # POST /company_financial_records or /company_financial_records.json
  def create
    @company_financial_record = CompanyFinancialRecord.new(company_financial_record_params)
    random_number = rand(10**2..10**3 - 1).to_s
    generate_reference = "#{SecureRandom.alphanumeric(2).upcase}-#{random_number}"
    @company_financial_record.update(reference: generate_reference)
      if @company_financial_record.save

         render json: @company_financial_record, status: :created
      else
      render json: @company_financial_record.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /company_financial_records/1 or /company_financial_records/1.json
  def update
     @company_financial_record = CompanyFinancialRecord.find_by(id: params[:id])
      if @company_financial_record.update(company_financial_record_params)
         render :show, status: :ok, location: @company_financial_record 
      else
         render json: @company_financial_record.errors, status: :unprocessable_entity 
      
    end
  end

  # DELETE /company_financial_records/1 or /company_financial_records/1.json
  def destroy
    @company_financial_record.destroy!
      head :no_content 
  end



  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_financial_record
      @company_financial_record = CompanyFinancialRecord.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def company_financial_record_params
      params.require(:company_financial_record).permit(:category, :is_intercompany, :amount,
       :description, :transaction_type, :company, :date, :counterparty, :account_id)
    end
end
