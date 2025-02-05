class IpPoolsController < ApplicationController




  set_current_tenant_through_filter

  before_action :set_tenant







  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account =ActsAsTenant.current_tenant 
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  def create
    @ip_pool = IpPool.new(
      start_ip: params[:start_ip],
      end_ip: params[:end_ip],
      pool_name: params[:pool_name],
      description: params[:description]
    )

    ip_pool_id = fetch_ip_pool
    if ip_pool_id && @ip_pool.save
      @ip_pool.update(ip_pool_id: ip_pool_id)
      render json: @ip_pool, status: :created

    else
      render json: { error: "Failed to create ip pool" }, status: :unprocessable_entity
  end

end





  def index
    @ip_pools = IpPool.all
    render json: @ip_pools, status: :ok
  end

  def update
    @ip_pool = IpPool.find_by(id: params[:id])
    if @ip_pool
      @ip_pool.update(start_ip: params[:start_ip], end_ip: params[:end_ip],
        pool_name: params[:pool_name], description: params[:description])
      render json: @ip_pool, status: :ok
    else
      render json: { error: "Ip pool not found" }, status: :not_found
    end

  end


  private


def fetch_ip_pool
  router_name = params[:router_name]
        
  nas_router = NasRouter.find_by(name: router_name)
if nas_router
  router_ip_address = nas_router.ip_address
    router_password = nas_router.password
   router_username = nas_router.username

else

  # puts 'router not found'

  render json: { error: "Router not found" }, status: :not_found
end

pool_name = params[:pool_name]

start_ip = params[:start_ip]
end_ip = params[:end_ip]


request_body2 = {
    
"name" => params[:pool_name],
"ranges" => start_ip + "-" + end_ip,
"next-pool" => "none",

}

uri = URI("http://#{router_ip_address}/rest/ip/pool/add")
request = Net::HTTP::Post.new(uri)

request.basic_auth router_username, router_password
request.body = request_body2.to_json
request['Content-Type'] = 'application/json'

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end
if response.is_a?(Net::HTTPSuccess)
  data = JSON.parse(response.body)
  return data['ret']
else
puts "Failed to post ip pool: #{response.code} - #{response.message}"
end 



end


 # "name": "any",
  # "next-pool": "any",
  # "ranges": "any",
  # {{baseUrl}}/ip/pool/remove
  # {{baseUrl}}/ip/pool/add

end