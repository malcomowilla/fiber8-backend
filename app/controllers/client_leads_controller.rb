class ClientLeadsController < ApplicationController
  # before_action :set_client_lead, only: %i[ show edit update destroy ]


  set_current_tenant_through_filter

  before_action :set_tenant


  # GET /client_leads or /client_leads.json
  def index
    @client_leads = ClientLead.all
    render json: @client_leads
  end

  # GET /client_leads/1 or /client_leads/1.json
  def show
  end



  def set_tenant

    host = request.headers['X-Subdomain'] 
    # Rails.logger.info("Setting tenant for host: #{host}")
  
    @account = Account.find_by(subdomain: host)
    set_current_tenant(@account)
  
    unless @account
      render json: { error: 'Invalid tenant' }, status: :not_found
    end
    
  end
  # GET /client_leads/new
  def new
    @client_lead = ClientLead.new
  end

  # GET /client_leads/1/edit
  def edit
  end

  # POST /client_leads or /client_leads.json
  def create
    @client_lead = ClientLead.new(client_lead_params)

      if @client_lead.save
        render json: @client_lead, status: :created
      else
         render json: @client_lead.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /client_leads/1 or /client_leads/1.json
  def update
    @client_lead = ClientLead.find_by(id: params[:id])
      if @client_lead.update(client_lead_params)
        render json: @client_lead, status: :ok
      else
        render json: @client_lead.errors, status: :unprocessable_entity 
      
    end
  end

  # DELETE /client_leads/1 or /client_leads/1.json
  def destroy
    @client_lead = ClientLead.find(params[:id])
    @client_lead.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client_lead
      @client_lead = ClientLead.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_lead_params
      params.require(:client_lead).permit(:name, :email, :company_name, :phone_number)
    end
end
