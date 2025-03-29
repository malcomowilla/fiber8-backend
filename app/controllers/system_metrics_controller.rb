

class SystemMetricsController < ApplicationController
  
  set_current_tenant_through_filter

  before_action :set_tenant

  require 'open3'


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
system_metrics = SystemMetric.all

    if system_metrics
      # Render the cached data
      render json: { system_metrics: system_metrics }, status: :ok
    else
      # Handle case where cache is empty
      render json: { error: "No system metrics found for tenant #{@tenant.id}" }, status: :not_found
    end
end



def check_services
  services = {
    freeradius: service_status("freeradius"),
    wireguard: service_status("wg-quick@wg0") # Adjust based on your WireGuard service name
  }

  render json: services
end

def restart_service
  service_name = params[:service]
  
  if ["freeradius", "wg-quick@wg0"].include?(service_name)
    stdout, stderr, status = Open3.capture3("systemctl restart #{service_name}")
    
    if status.success?
      render json: { message: "#{service_name} restarted successfully" }, status: :ok
    else
      render json: { error: "Failed to restart #{service_name}: #{stderr}" }, status: :unprocessable_entity
    end
  else
    render json: { error: "Invalid service name" }, status: :bad_request
  end
end


private

def service_status(service)
  stdout, stderr, status = Open3.capture3("systemctl is-active #{service}")
  active = stdout.strip == "active"

  last_restart, _ = Open3.capture3("systemctl show #{service} --property=ActiveEnterTimestamp")
  
  {
    running: active,
    last_restart: last_restart.strip.split('=').last || "Unknown"
  }
end



end