class IpPoolsController < ApplicationController



  load_and_authorize_resource

  set_current_tenant_through_filter

  before_action :set_tenant







  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account =ActsAsTenant.current_tenant 
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
    set_current_tenant(@account)
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  def create

    host = request.headers['X-Subdomain'] 

    if  host == 'demo'
      @ip_pool = IpPool.new(
        ip_pool_params
      )
      @ip_pool.save
      render json: @ip_pool, status: :created
    else

      @ip_pool = IpPool.new(
        ip_pool_params
      )

      ip_pool_id_mikrotik = fetch_ip_pool
      if ip_pool_id_mikrotik && @ip_pool.save
        @ip_pool.update(ip_pool_id_mikrotik: ip_pool_id_mikrotik)
        render json: @ip_pool, status: :created
  
      else
        render json: { error: "Failed to create ip pool" }, status: :unprocessable_entity
    end
    end
   
end





  def index
    @ip_pools = IpPool.all
    render json: @ip_pools, status: :ok
  end


  def update
    host = request.headers['X-Subdomain'] 


    @ip_pool = IpPool.find_by(id: params[:id])



    if host === 'demo'
      if @ip_pool
        @ip_pool.update(start_ip: params[:start_ip], end_ip: params[:end_ip],
        pool_name: params[:pool_name], description: params[:description])
      render json: @ip_pool, status: :ok
      else
        
        render json: { error: "Ip pool not found" }, status: :not_found
      end
    else

      router_name = params[:router_name]
      nas_router = NasRouter.find_by(name: router_name)
        router_ip_address = nas_router.ip_address
        router_password = nas_router.password
        router_username = nas_router.username
      
  
      return render json: { error: "router not found" }, status: :not_found unless nas_router
  
      ip_pool_id = @ip_pool.ip_pool_id
  
  
        unless ip_pool_id.present?
          return render json: { error: "ip pool id missing in package" }, status: :unprocessable_entity
        end
  
  
      request_body = {
      
          "name" => params[:pool_name],
          "ranges" => params[:start_ip] + "-" + params[:end_ip],
          "next-pool" => "none",
          "comment" => params[:description]
      }  
  
  
  
      if @ip_pool
      
  
        begin
          uri = URI("http://#{router_ip_address}/rest/ip/pool/#{ip_pool_id}") 
          req = Net::HTTP::Patch.new(uri)
             
  
              req.basic_auth router_username, router_password
             
              req['Content-Type'] = 'application/json'
  
    req.body = request_body.to_json
  
    response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
  
  
  if response.is_a?(Net::HTTPSuccess) 
    @ip_pool.update(start_ip: params[:start_ip], end_ip: params[:end_ip],
    pool_name: params[:pool_name], description: params[:description])
  render json: @ip_pool, status: :ok
  else
    puts "Failed to update ip pool : #{response.code} - #{response.message}"
  
    render json: { error: "Failed to update package" }, status: :unprocessable_entity
  
  end
  
  
  rescue Net::OpenTimeout, Net::ReadTimeout
  render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
  rescue Errno::ECONNREFUSED
  render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
  rescue StandardError => e
  render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  
  end
  
      else
        render json: { error: "Ip pool not found" }, status: :not_found
      end
      
    end
   

  end



  def destroy
    @ip_pool = IpPool.find_by(id: params[:id])



    router_name = params[:router_name]
    nas_router = NasRouter.find_by(name: router_name)
      router_ip_address = nas_router.ip_address
      router_password = nas_router.password
      router_username = nas_router.username
    

    return render json: { error: "router not found" }, status: :not_found unless nas_router

    ip_pool_id = @ip_pool.ip_pool_id


      unless ip_pool_id.present?
        return render json: { error: "ip pool id missing in package" }, status: :unprocessable_entity
      end




      begin
        uri = URI("http://#{router_ip_address}/rest/ip/pool/#{ip_pool_id}")
    
        request = Net::HTTP::Delete.new(uri)
    
        request.basic_auth(router_username, router_password)
    
        response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) { |http| http.request(request) }
    
        if response.is_a?(Net::HTTPSuccess) 
          @ip_pool.destroy
          head :no_content
        else
          error_message = "Failed to delete ip pool- #{response.code} #{response.message}"
          render json: { error: error_message }, status: :unprocessable_entity
        end
    
      rescue Net::OpenTimeout, Net::ReadTimeout
        render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
      rescue Errno::ECONNREFUSED
        render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
      rescue StandardError => e
        render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
      
      end

      
  end


  private


  def ip_pool_params
    params.permit(:pool_name, :start_ip, :end_ip, :description)
  end






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