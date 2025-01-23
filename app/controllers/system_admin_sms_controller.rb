class SystemAdminSmsController < ApplicationController
  before_action :set_system_admin_sm, only: %i[ show edit update destroy ]

  # GET /system_admin_sms or /system_admin_sms.json
  def index
    @system_admin_sms = SystemAdminSm.all
  end

  # GET /system_admin_sms/1 or /system_admin_sms/1.json
  def show
  end

  # GET /system_admin_sms/new
  def new
    @system_admin_sm = SystemAdminSm.new
  end

  # GET /system_admin_sms/1/edit
  def edit
  end

  # POST /system_admin_sms or /system_admin_sms.json
  def create
    @system_admin_sm = SystemAdminSm.new(system_admin_sm_params)

    respond_to do |format|
      if @system_admin_sm.save
        format.html { redirect_to system_admin_sm_url(@system_admin_sm), notice: "System admin sm was successfully created." }
        format.json { render :show, status: :created, location: @system_admin_sm }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_admin_sm.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_admin_sms/1 or /system_admin_sms/1.json
  def update
    respond_to do |format|
      if @system_admin_sm.update(system_admin_sm_params)
        format.html { redirect_to system_admin_sm_url(@system_admin_sm), notice: "System admin sm was successfully updated." }
        format.json { render :show, status: :ok, location: @system_admin_sm }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_admin_sm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_admin_sms/1 or /system_admin_sms/1.json
  def destroy
    @system_admin_sm.destroy!

    respond_to do |format|
      format.html { redirect_to system_admin_sms_url, notice: "System admin sm was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_admin_sm
      @system_admin_sm = SystemAdminSm.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def system_admin_sm_params
      params.require(:system_admin_sm).permit(:user, :message, :status, :date, :system_user)
    end
end
