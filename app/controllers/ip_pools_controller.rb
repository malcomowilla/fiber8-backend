class IpPoolsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :pool_not_found_response
  load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity

  def index
    @ip_pools = IpPool.includes(:nas_router).all
    render json: @ip_pools
  end

  def create
    @ip_pool = IpPool.new(ip_pool_params)
    @ip_pool.account = @account

    if @ip_pool.save
      ActivtyLog.create(action: 'create', ip: request.remote_ip,
        description: "Created IP pool #{@ip_pool.name}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)

      if ActiveModel::Type::Boolean.new.cast(params[:sync_immediately])
        begin
          MikrotikPoolSyncService.sync(@ip_pool)
        rescue MikrotikPoolSyncService::SyncError => e
          render json: @ip_pool.reload.as_json.merge(sync_error: e.message), status: :created and return
        end
      end

      render json: @ip_pool.reload, status: :created
    else
      render json: { errors: @ip_pool.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @ip_pool.update(ip_pool_params)
      ActivtyLog.create(action: 'update', ip: request.remote_ip,
        description: "Updated IP pool #{@ip_pool.name}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)
      render json: @ip_pool
    else
      render json: { errors: @ip_pool.errors.full_messages }, status: :unprocessable_entity
    end
  end

  


def destroy
  begin
    MikrotikPoolSyncService.delete(@ip_pool)
  rescue MikrotikPoolSyncService::SyncError => e
    render json: { error: "Could not remove pool from router: #{e.message}" }, status: :unprocessable_entity
    return
  end

  @ip_pool.destroy
  ActivtyLog.create(action: 'delete', ip: request.remote_ip,
    description: "Deleted IP pool #{@ip_pool.name}",
    user_agent: request.user_agent, user: current_user.username || current_user.email,
    date: Time.current)
  head :no_content
end



  def sync
    MikrotikPoolSyncService.sync(@ip_pool)
    render json: @ip_pool.reload
  rescue MikrotikPoolSyncService::SyncError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sync_all
    @account.ip_pools.find_each { |pool| SyncIpPoolJob.perform_later(pool.id) }
    render json: { queued: @account.ip_pools.count }
  end

  def suggest_range
    render json: MikrotikPoolSyncService.suggest_range(@account)
  rescue MikrotikPoolSyncService::SyncError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def find_ip_pool
    @ip_pool = IpPool.find(params[:id])
  end

  def ip_pool_params
    params.require(:ip_pool).permit(
      :name, :nas_router_id, :ip_range_start, :ip_range_end,
      :subnet_mask, :gateway, :primary_dns, :secondary_dns,
      :description, :status
    )
  end

  def pool_not_found_response
    render json: { error: 'IP Pool Not Found' }, status: :not_found
  end
end