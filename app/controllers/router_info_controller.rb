
class RouterInfoController < ApplicationController

set_current_tenant_through_filter
before_action :set_tenant

require 'bigdecimal'
require 'bigdecimal/util'




  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    # EmailConfiguration.configure(@current_account)
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])

  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end




  def fetch_trafic_stats
Rails.logger.info "Fetching trafic stats#{params[:id]}"
  router = NasRouter.find_by(id: params[:id])

  return [] unless router

  router_ip = router.ip_address
  router_username = router.username
  router_password = router.password 

  stats = []

  Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
    output = ssh.exec!('/ppp active print detail')
    Rails.logger.info "PPPoE stats: #{output}"

     traffic_output = ssh.exec!("/interface monitor-traffic interface=#{params[:interface]} once")

      rx_speed = extract_speed_direct(traffic_output[/rx-bits-per-second:\s+(\S+)/, 1])
      tx_speed = extract_speed_direct(traffic_output[/tx-bits-per-second:\s+(\S+)/, 1])

      stats << {
        download_speed: rx_speed,
        upload_speed: tx_speed,
      }
  end

  stats

rescue => e
  Rails.logger.error "Failed to fetch PPPoE stats: #{e.message}"
  []
end

# 🛠 This is the simple parser that accepts whatever Mikrotik gave
def extract_speed_direct(raw_value)
  return "0 bps" if raw_value.blank?

  # Mikrotik gives with unit already, just format spacing better
  if raw_value =~ /^(\d+(\.\d+)?)([a-zA-Z]+)$/
    number = Regexp.last_match(1)
    unit = Regexp.last_match(3)
    "#{number} #{unit}"
  else
    raw_value
  end
end

def trafic_stats
  stats = fetch_trafic_stats
  render json: stats
end


def get_router_interface
  id = params[:id]
    nas_router = NasRouter.find_by(id: id)
  
    unless nas_router
      return render json: { error: "Router not found" }, status: :not_found
    end
  
    router_ip_address = nas_router.ip_address
    router_username = nas_router.username
    router_password = nas_router.password
  
    # Fetch router resource data
    uri = URI("http://#{router_ip_address}/rest/interface")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(router_username, router_password)
  
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  
    unless response.is_a?(Net::HTTPSuccess)
      return render json: { error: "Failed to fetch router info: #{response.code} - #{response.message}" }, status: :internal_server_error
    end
  
    # Parse and customize the data
   parsed = JSON.parse(response.body)
customized_data = customize_interfaces(parsed)
  
    # Log and return the customized data
    Rails.logger.info "Customized router info data interface: #{parsed}"

    render json: customized_data
end


def customize_interfaces(data)
  data.map do |interface|
    {
      default_name: interface["default-name"],
      name: interface["name"],
      id: interface[".id"],
      
      # type: interface["type"],
      # mac_address: interface["mac-address"],
      # rx_packet: interface["rx-packet"],
      # tx_packet: interface["tx-packet"],
      # running: interface["running"]
    }
  end
end


  def router_info
    # Fetch router details
    # Rails.logger.info "Fetching router info#{params[:id]}"
    id = params[:id]
    nas_router = NasRouter.find_by(id: id)
  
    unless nas_router
      return render json: { error: "Router not found" }, status: :not_found
    end
  
    router_ip_address = nas_router.ip_address
    router_username = nas_router.username
    router_password = nas_router.password
  
    # Fetch router resource data
    uri = URI("http://#{router_ip_address}/rest/system/resource")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(router_username, router_password)
  
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  
    unless response.is_a?(Net::HTTPSuccess)
      return render json: { error: "Failed to fetch router info: #{response.code} - #{response.message}" }, status: :internal_server_error
    end
  
    # Parse and customize the data
    data = JSON.parse(response.body)
    customized_data = customize_router_data(data)
  
    # Log and return the customized data
    Rails.logger.info "Customized router info data: #{customized_data}"
    Rails.logger.info "router info data: #{data}"

    render json: customized_data
  end
  
  private
  
  def customize_router_data(data)
    {
      architecture_name: data["architecture-name"],
      board_name: data["board-name"],
      cpu: data["cpu"],
      cpu_count: data["cpu-count"],
      cpu_frequency: "#{data["cpu-frequency"]} MHz",
      cpu_load: "#{data["cpu-load"]}%",
      memory_usage: format_memory_usage(data["total-memory"], data["free-memory"]),
      disk_usage: format_disk_usage(data["total-hdd-space"], data["free-hdd-space"]),
      uptime: data["uptime"],
      version: data["version"],
      build_time: data["build-time"]
    }
  end
  
  def format_memory_usage(total_memory, free_memory)
    total_memory_mb = BigDecimal(total_memory) / (1024 * 1024)
    free_memory_mb = BigDecimal(free_memory) / (1024 * 1024)
    used_memory_mb = total_memory_mb - free_memory_mb
  
    {
      total: "#{format_number(total_memory_mb)} MB",
      free: "#{format_number(free_memory_mb)} MB",
      used: "#{format_number(used_memory_mb)} MB"
    }
  end



  def format_number(value)
    rounded_value = value.round(2).to_f
    rounded_value.to_s.sub(/\.?0+$/, '') # Removes unnecessary .00 or trailing zeros
  end
  
  def format_disk_usage(total_hdd_space, free_hdd_space)
    total_hdd_gb = (total_hdd_space.to_f / 1024 / 1024 / 1024).round(2)
    free_hdd_gb = (free_hdd_space.to_f / 1024 / 1024 / 1024).round(2)
    used_hdd_gb = total_hdd_gb - free_hdd_gb
  
    {
      total: "#{total_hdd_gb} GB",
      free: "#{free_hdd_gb} GB",
      used: "#{used_hdd_gb} GB"
    }
  end
  
  def format_uptime(uptime)
    # Convert uptime from seconds to a readable format (e.g., 21h21m42s)
    seconds = uptime.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
  
    "#{hours}h #{minutes}m #{seconds}s"
  end


end