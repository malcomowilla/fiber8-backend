class NetworkConnectionsController < ApplicationController



set_current_tenant_through_filter

before_action :set_tenant







  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


  def index
    render json: NetworkConnection.all.map(&:as_map_json)
  end

  def show
    render json: @connection.as_map_json
  end

  def create
    connection = NetworkConnection.new(connection_params)
    if connection.save
      render json: connection.as_map_json, status: :created
    else
      render json: { errors: connection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @connection.update(connection_params)
      render json: @connection.as_map_json
    else
      render json: { errors: @connection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @connection.destroy
    head :no_content
  end

  private

  def set_connection
    @connection = NetworkConnection.find(params[:id])
  end

  def connection_params
    source = params[:network_connection].present? ? params.require(:network_connection) : params
    source.permit(
      :sourceKind, :sourceId, :targetKind, :targetId,
      :category, :cableType, :label, :bandwidthMbps, :distanceM, :status, path: []
    ).tap do |p|
      p[:source_kind] = p.delete(:sourceKind)
      p[:source_id]   = p.delete(:sourceId)
      p[:target_kind] = p.delete(:targetKind)
      p[:target_id]   = p.delete(:targetId)
      p[:cable_type]  = p.delete(:cableType) if p[:cableType]
      p[:bandwidth_mbps] = p.delete(:bandwidthMbps) if p[:bandwidthMbps]
      p[:distance_m]  = p.delete(:distanceM) if p[:distanceM]
    end
  end
end