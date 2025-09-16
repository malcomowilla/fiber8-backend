class EquipmentController < ApplicationController
  before_action :set_equipment, only: %i[ show edit update destroy ]


  load_and_authorize_resource

  set_current_tenant_through_filter

  before_action :set_tenant

  before_action :update_last_activity


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



















  # GET /equipment or /equipment.json
  def index
    @equipment = Equipment.all
    render json: @equipment
  end


  # POST /equipment or /equipment.json
  def create
    @equipment = Equipment.new(equipment_params)

      if @equipment.save
       render json: @equipment, status: :created
      else
   render json: @equipment.errors, status: :unprocessable_entity 
    
    end
  end

  # PATCH/PUT /equipment/1 or /equipment/1.json
  def update
      if @equipment.update(equipment_params)
       render json: @equipment, status: :ok
      else
       render json: @equipment.errors, status: :unprocessable_entity 
      end
  end

  # DELETE /equipment/1 or /equipment/1.json
  def destroy
    @equipment = set_equipment
    @equipment.destroy!

      head :no_content 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equipment
      @equipment = Equipment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def equipment_params
      params.require(:equipment).permit(:user, :device_type, :name, :model, :serial_number,
       :price, :amount_paid, :account_number)
    end
end



