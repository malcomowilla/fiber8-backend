class PackagesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
  load_and_authorize_resource except: [:allow_get_packages]

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity

  def index
    render json: Package.all, each_serializer: PackageSerializer
  end

  def create
    @package = @account.packages.new(package_params)

    if @package.save
      sync_error = sync_package if truthy?(params[:sync_immediately])

      ActivtyLog.create(action: 'create', ip: request.remote_ip,
        description: "Created package #{@package.name}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)

      render json: serialize(@package).merge(sync_error: sync_error), status: :created
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @package.update(package_params)
      sync_error = sync_package if truthy?(params[:sync_immediately])

      ActivtyLog.create(action: 'update', ip: request.remote_ip,
        description: "Updated package #{@package.name}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)

      render json: serialize(@package).merge(sync_error: sync_error)
    else
      render json: { errors: @package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def sync
    MikrotikProfileSyncService.sync(@package)
    render json: serialize(@package.reload)
  rescue MikrotikProfileSyncService::SyncError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sync_all
    @account.packages.find_each { |pkg| SyncPackageJob.perform_later(pkg.id) }
    render json: { queued: @account.packages.count }
  end

  def destroy
    begin
      MikrotikProfileSyncService.delete(@package)
    rescue MikrotikProfileSyncService::SyncError => e
      render json: { error: "Could not remove profile from router: #{e.message}" },
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

  # Returns the error message string on failure, nil on success — same
  # shape as the hotspot voucher flow's sync_status/sync_error, just
  # surfaced immediately in the response instead of only on the record.
  def sync_package
    MikrotikProfileSyncService.sync(@package)
    nil
  rescue MikrotikProfileSyncService::SyncError => e
    e.message
  end

  def serialize(package)
    ActiveModelSerializers::SerializableResource.new(package, serializer: PackageSerializer).as_json
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
      :aggregation, :daily_charge, :nas_router, :ip_pool
    )
  end

  def not_found_response
    render json: { error: 'Package not found' }, status: :not_found
  end
end