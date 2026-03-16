class AccessPointsController < ApplicationController

  set_current_tenant_through_filter
  before_action :set_tenant







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




  # GET /access_points or /access_points.json
  def index
    @access_points = AccessPoint.all

    render json: @access_points
  end

  # GET /access_points/1 or /access_points/1.json
  

  def create
    @access_point = AccessPoint.new(access_point_params)

      if @access_point.save
      render json: @access_point, status: :created
      else
      render json: @access_point.errors, status: :unprocessable_entity 
      end
    
  end

  def update
    access_point = AccessPoint.find_by(id: params[:id])
      if access_point.update(access_point_params)
        render json: @access_point, status: :ok
      else
       render json: @access_point.errors, status: :unprocessable_entity 
      end
  end



  def destroy
    access_point = AccessPoint.find_by(id: params[:id])
    access_point.destroy!

    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_access_point
      @access_point = AccessPoint.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def access_point_params
      params.require(:access_point).permit(:name, :ping,
       :status, :checked_at, :account_id, :ip, :response, :reachable)
    end
end
