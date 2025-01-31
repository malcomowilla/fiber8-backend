class SystemAdminWebAuthnCredentialsController < ApplicationController
  before_action :set_system_admin_web_authn_credential, only: %i[ show edit update destroy ]

  # GET /system_admin_web_authn_credentials or /system_admin_web_authn_credentials.json
  def index
    @system_admin_web_authn_credentials = SystemAdminWebAuthnCredential.all
  end

  # GET /system_admin_web_authn_credentials/1 or /system_admin_web_authn_credentials/1.json
  def show
  end

  # GET /system_admin_web_authn_credentials/new
  def new
    @system_admin_web_authn_credential = SystemAdminWebAuthnCredential.new
  end

  # GET /system_admin_web_authn_credentials/1/edit
  def edit
  end

  # POST /system_admin_web_authn_credentials or /system_admin_web_authn_credentials.json
  def create
    @system_admin_web_authn_credential = SystemAdminWebAuthnCredential.new(system_admin_web_authn_credential_params)

    respond_to do |format|
      if @system_admin_web_authn_credential.save
        format.html { redirect_to system_admin_web_authn_credential_url(@system_admin_web_authn_credential), notice: "System admin web authn credential was successfully created." }
        format.json { render :show, status: :created, location: @system_admin_web_authn_credential }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_admin_web_authn_credential.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_admin_web_authn_credentials/1 or /system_admin_web_authn_credentials/1.json
  def update
    respond_to do |format|
      if @system_admin_web_authn_credential.update(system_admin_web_authn_credential_params)
        format.html { redirect_to system_admin_web_authn_credential_url(@system_admin_web_authn_credential), notice: "System admin web authn credential was successfully updated." }
        format.json { render :show, status: :ok, location: @system_admin_web_authn_credential }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_admin_web_authn_credential.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_admin_web_authn_credentials/1 or /system_admin_web_authn_credentials/1.json
  def destroy
    @system_admin_web_authn_credential.destroy!

    respond_to do |format|
      format.html { redirect_to system_admin_web_authn_credentials_url, notice: "System admin web authn credential was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_admin_web_authn_credential
      @system_admin_web_authn_credential = SystemAdminWebAuthnCredential.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def system_admin_web_authn_credential_params
      params.require(:system_admin_web_authn_credential).permit(:webauthn_id, :public_key, :sign_count, :system_admin_id)
    end
end
