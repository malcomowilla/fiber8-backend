class CompanyIdsController < ApplicationController
  before_action :set_company_id, only: %i[ show edit update destroy ]
before_action :set_tenant
  # GET /company_ids or /company_ids.json
  def index
    @company_ids = CompanyId.all
    render json: @company_ids
  end




  def set_tenant
  host = request.headers['X-Subdomain']
  company_id = request.headers['X-Company-Id']

  @account = if host.present?
                Account.find_by(subdomain: host)
              elsif company_id.present?
                Account.joins(:company_id).find_by(company_ids: { company_id: company_id })
              end

  if @account
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  else
    render json: { error: 'Invalid tenant or missing headers' }, status: :not_found
  end
end





  # GET /company_ids/1 or /company_ids/1.json
  def show
  end

  # GET /company_ids/new
  def new
    @company_id = CompanyId.new
  end

  # GET /company_ids/1/edit
  def edit
  end

  # POST /company_ids or /company_ids.json
  def create
    @company_id = CompanyId.new(company_id_params)

    respond_to do |format|
      if @company_id.save
        format.html { redirect_to @company_id, notice: "Company was successfully created." }
        format.json { render :show, status: :created, location: @company_id }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @company_id.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /company_ids/1 or /company_ids/1.json
  def update
    respond_to do |format|
      if @company_id.update(company_id_params)
        format.html { redirect_to @company_id, notice: "Company was successfully updated." }
        format.json { render :show, status: :ok, location: @company_id }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @company_id.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /company_ids/1 or /company_ids/1.json
  def destroy
    @company_id.destroy!

    respond_to do |format|
      format.html { redirect_to company_ids_path, status: :see_other, notice: "Company was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_id
      @company_id = CompanyId.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def company_id_params
      params.require(:company_id).permit(:company_id, :account_id)
    end
end
