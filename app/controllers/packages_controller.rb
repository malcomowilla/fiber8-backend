class PackagesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
  load_and_authorize_resource except: [:allow_get_packages]

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity

  def index
    render json: Package.includes(package_routers: [:nas_router, :ip_pool]).all,
           each_serializer: PackageSerializer
  end

  def create
  @package = @account.packages.new(package_params.except(:package_routers_attributes))
  @package.package_routers.build(router_attrs)

  if @package.save
    sync_results = sync_all_routers if truthy?(params[:sync_immediately])

    ActivtyLog.create(action: 'create', ip: request.remote_ip,
      description: "Created package #{@package.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    payload = ActiveModelSerializers::SerializableResource.new(
      @package.reload, serializer: PackageSerializer
    ).as_json
    render json: payload.merge(sync_errors: sync_results&.compact), status: :created
  else
    render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
  end
end

def update
  if @package.update(package_params.except(:package_routers_attributes))
    sync_router_assignments!(router_attrs) if params[:package][:routers].present?
    sync_results = sync_all_routers if truthy?(params[:sync_immediately])

    ActivtyLog.create(action: 'update', ip: request.remote_ip,
      description: "Updated package #{@package.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    payload = ActiveModelSerializers::SerializableResource.new(
      @package.reload, serializer: PackageSerializer
    ).as_json
    render json: payload.merge(sync_errors: sync_results&.compact)
  else
    render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
  end
end

  def destroy
    errors = @package.package_routers.filter_map do |pr|
      MikrotikProfileSyncService.delete(pr)
      nil
    rescue MikrotikProfileSyncService::SyncError => e
      "#{pr.nas_router.name}: #{e.message}"
    end

    if errors.any?
      render json: { error: "Could not remove profile from router(s): #{errors.join('; ')}" },
             status: :unprocessable_entity
      return
    end

    @package.destroy!
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
      description: "Deleted package #{@package.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)
    head :no_content
  end

  private

  def sync_all_routers
    @package.package_routers.map do |pr|
      MikrotikProfileSyncService.sync(@package, pr)
      nil
    rescue MikrotikProfileSyncService::SyncError => e
      "#{pr.nas_router.name}: #{e.message}"
    end
  end

  # Replace the router/pool set wholesale on update — simplest correct
  # behavior for a small list; swap for a diff if lists get long.
  def sync_router_assignments!(attrs)
    @package.package_routers.destroy_all
    @package.package_routers.create!(attrs)
  end

  def router_attrs
    (params[:package][:routers] || []).map.with_index do |r, i|
      { nas_router_id: r[:nas_router_id], ip_pool_id: r[:ip_pool_id], is_default: i.zero? }
    end
  end

  def truthy?(val)
    ActiveModel::Type::Boolean.new.cast(val)
  end

  def set_tenant
    @account = Account.find_by!(subdomain: request.headers['X-Subdomain'])
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def package_params
    params.require(:package).permit(
      :name, :router_profile_name, :description, :plan_type, :status, :public,
      :download_limit, :upload_limit, :price, :validity, :validity_period_units,
      :burst_upload_speed, :burst_download_speed,
      :burst_threshold_upload, :burst_threshold_download, :burst_time,
      :fup_enabled, :fup_data_limit, :fup_data_unit, :fup_throttle_plan_id,
      :aggregation, :daily_charge
    )
  end


  def not_found_response
    render json: { error: 'Package not found' }, status: :not_found
  end
end