class CompanyLeadsController < ApplicationController
  # before_action :set_company_lead, only: %i[ show edit update destroy ]

before_action :update_last_activity







   def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end


# set_current_tenant_through_filter

# before_action :set_tenant

  # GET /company_leads or /company_leads.json
  def index
    @company_leads = CompanyLead.all
    render json: @company_leads
  end



  

  # GET /company_leads/1 or /company_leads/1.json
  def show
  end

  # GET /company_leads/new
  def new
    @company_lead = CompanyLead.new
  end

  # GET /company_leads/1/edit
  def edit
  end




  # def set_tenant

  #   host = request.headers['X-Subdomain'] 
  #   # Rails.logger.info("Setting tenant for host: #{host}")
  
  #   @account = Account.find_by(subdomain: host)
  #   set_current_tenant(@account)
  
  #   unless @account
  #     render json: { error: 'Invalid tenant' }, status: :not_found
  #   end
    
  # end






  # POST /company_leads or /company_leads.json
  def create
    @company_lead = CompanyLead.new(company_lead_params)

      if @company_lead.save
       
        render json: @company_lead, status: :created
      else
        render json: @company_lead.errors, status: :unprocessable_entity 
      end
  
  end

  # PATCH/PUT /company_leads/1 or /company_leads/1.json
  def update
    @company_lead = set_company_lead
      if @company_lead.update(company_lead_params)
        render json: @company_lead, status: :ok
      else
         render json: @company_lead.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /company_leads/1 or /company_leads/1.json
  def destroy
    @company_lead = set_company_lead
    @company_lead.destroy!

     head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_lead
      @company_lead = CompanyLead.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def company_lead_params
      params.require(:company_lead).permit(:name, :company_name, :email, :message, :phone_number)
    end
end
