class ActivtyLogsController < ApplicationController
  before_action :set_activty_log, only: %i[ show edit update destroy ]
    set_current_tenant_through_filter

  before_action :set_tenant

  # GET /activty_logs or /activty_logs.json
  def index
    @activty_logs = ActivtyLog.all
    render json: @activty_logs
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
  # GET /activty_logs/1 or /activty_logs/1.json
  def show
  end

  # GET /activty_logs/new
  def new
    @activty_log = ActivtyLog.new
  end

  # GET /activty_logs/1/edit
  def edit
  end

  # POST /activty_logs or /activty_logs.json
  def create
    @activty_log = ActivtyLog.new(activty_log_params)

      if @activty_log.save
        format.html { redirect_to @activty_log, notice: "Activty log was successfully created." }
        format.json { render :show, status: :created, location: @activty_log }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @activty_log.errors, status: :unprocessable_entity }
      end
    
  end

  # PATCH/PUT /activty_logs/1 or /activty_logs/1.json
  def update
    respond_to do |format|
      if @activty_log.update(activty_log_params)
        format.html { redirect_to @activty_log, notice: "Activty log was successfully updated." }
        format.json { render :show, status: :ok, location: @activty_log }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activty_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activty_logs/1 or /activty_logs/1.json
  def destroy
    @activty_log.destroy!

    respond_to do |format|
      format.html { redirect_to activty_logs_path, status: :see_other, notice: "Activty log was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activty_log
      @activty_log = ActivtyLog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def activty_log_params
      params.require(:activty_log).permit(:action, :subject, :description, :user, :date, :account_id)
    end
end
