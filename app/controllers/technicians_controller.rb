class TechniciansController < ApplicationController
  before_action :set_technician, only: %i[ show edit update destroy ]
  before_action :set_tenant

  # GET /technicians or /technicians.json
  def index
    @technicians = Technician.all
    render json: @technicians
  end



  def set_tenant
      company_id = request.headers['X-Company-Id']

    @account =  Account.joins(:company_id).find_by(company_ids: { company_id: company_id })
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant technician' }, status: :not_found
  
    
  end
  # GET /technicians/1 or /technicians/1.json
  def show
  end

  # GET /technicians/new
  def new
    @technician = Technician.new
  end

  # GET /technicians/1/edit
  def edit
  end

  # POST /technicians or /technicians.json
  def signup
  company_id_param = params[:company_id]

  # 1️⃣ Validate company_id existence
  company_record = CompanyId.find_by(company_id: company_id_param)


  unless company_record
    return render json: { error: "Invalid company ID" }, status: :not_found
  end



  # 2️⃣ Set the correct tenant
    technician = Technician.new(technician_params)

    # 3️⃣ Save and validate
    if technician.save
      render json: {
        message: "Technician created successfully",
        technician: technician
      }, status: :created
    else
      render json: {
        errors: technician.errors.full_messages
      }, status: :unprocessable_entity
    
  end
end









def signin
  user = Technician.find_by(email: params[:email])

  if user&.authenticate(params[:password])
    token = generate_token(technician_id: user.id)
    user.update(last_login_at: Time.current, status: 'active')

    render json: {
      message: "Login successful",
      token: token,
      technician: {
        id: user.id,
        email: user.email,
        username: user.username
      }
    }, status: :ok
  else
    render json: { error: "Invalid email or password" }, status: :unauthorized
  end
end


  # PATCH/PUT /technicians/1 or /technicians/1.json
  def update
    respond_to do |format|
      if @technician.update(technician_params)
        format.html { redirect_to @technician, notice: "Technician was successfully updated." }
        format.json { render :show, status: :ok, location: @technician }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @technician.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /technicians/1 or /technicians/1.json
  def destroy
    @technician.destroy!

    respond_to do |format|
      format.html { redirect_to technicians_path, status: :see_other, notice: "Technician was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_technician
      @technician = Technician.find(params[:id])
    end





     def generate_token(payload)
        JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
      end


      

    # Only allow a list of trusted parameters through.
    def technician_params
      params.require(:technician).permit(:email, :username, :phone_number, :password_digest, :account_id)
    end
end
