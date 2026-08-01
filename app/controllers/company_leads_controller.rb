class CompanyLeadsController < ApplicationController
  before_action :update_last_activity
  rescue_from ArgumentError, with: :handle_invalid_status

  STATUSES = %w[new contacted qualified converted lost].freeze

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  # GET /company_leads
  def index
    leads = CompanyLead.all.order(created_at: :desc)
    render json: {
      leads: leads,
      stats: STATUSES.index_with { |s| CompanyLead.where(status: s).count }
                      .merge(total: leads.size)
    }
  end

  def show
  end

  def new
    @company_lead = CompanyLead.new
  end

  def edit
  end

  # POST /company_leads
  def create
    @company_lead = CompanyLead.new(company_lead_params)
    if @company_lead.save
      render json: @company_lead, status: :created
    else
      render json: @company_lead.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /company_leads/1
  def update
    @company_lead = set_company_lead
    if @company_lead.update(company_lead_params)
      render json: @company_lead, status: :ok
    else
      render json: @company_lead.errors, status: :unprocessable_entity
    end
  end

  # DELETE /company_leads/1
  def destroy
    @company_lead = set_company_lead
    @company_lead.destroy!
    head :no_content
  end

  private

  def set_company_lead
    @company_lead = CompanyLead.find_by_id(params[:id])
  end


def company_lead_params
  params.require(:company_lead).permit(:name, :company_name, :email, :message, :phone_number, :status, :source)
end


  def handle_invalid_status(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end
end