class NetworkDevicesController < ApplicationController


set_current_tenant_through_filter

before_action :set_tenant



  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end







  def index
    render json: NetworkDevice.all.map(&:as_map_json)
  end

  def show
    render json: @device.as_map_json
  end

  def create
    device = NetworkDevice.new(device_params)
    if device.save
      render json: device.as_map_json, status: :created
    else
      render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @device.update(device_params)
      render json: @device.as_map_json
    else
      render json: { errors: @device.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @device.destroy
    head :no_content
  end

  private

  def set_device
    @device = NetworkDevice.find(params[:id])
  end

  def device_params
    source = params[:network_device].present? ? params.require(:network_device) : params
    source.permit(:type, :name, :identifier, :lat, :lng, :address, :status, :description, :routerId, :parentId).tap do |p|
      p[:type_key] = p.delete(:type) if p[:type].present?
      p[:router_id] = p.delete(:routerId) if p[:routerId].present?
      if p[:parentId].present?
        p[:parent_id] = p.delete(:parentId)
        p[:parent_type] = 'Pop'
      end
    end
  end
end