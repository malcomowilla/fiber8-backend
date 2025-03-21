

class SystemMetricsController < ApplicationController
  
  set_current_tenant_through_filter

  before_action :set_tenant



  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    set_current_tenant(@account)
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end





def system_status
  @tenant = ActsAsTenant.current_tenant
system_metrics = SystemMetric.where(account_id: @tenant.id).first

    if system_metrics
      # Render the cached data
      render json: { system_metrics: system_metrics }, status: :ok
    else
      # Handle case where cache is empty
      render json: { error: "No system metrics found for tenant #{@tenant.id}" }, status: :not_found
    end
end






end