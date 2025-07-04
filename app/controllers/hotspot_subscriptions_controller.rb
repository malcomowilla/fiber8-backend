class HotspotSubscriptionsController < ApplicationController
  before_action :set_hotspot_subscription, only: %i[ show edit update destroy ]

  # GET /hotspot_subscriptions or /hotspot_subscriptions.json
  def index
    @hotspot_subscriptions = HotspotSubscription.all

  end
# }/ip/hotspot/active
# 
#
#RadAcct
 def get_active_hotspot_users
  active_sessions = RadAcct.where(acctstoptime: nil, framedprotocol: '')

  total_bytes = 0

  active_user_data = active_sessions.map do |session|
    download_bytes = session.acctinputoctets || 0
    upload_bytes = session.acctoutputoctets || 0
    session_total = download_bytes + upload_bytes
    total_bytes += session_total

    {
      username: session.username,
      ip_address: session.framedipaddress.to_s,
      mac_address: session.callingstationid,
      up_time: format_uptime(session.acctsessiontime),
      download: format_bytes(download_bytes),
      upload: format_bytes(upload_bytes),
      start_time: session.acctstarttime,
      nas_port: session.nasportid
    }
  end

  render json: {
    active_user_count: active_user_data.size,
    total_bandwidth: format_bytes(total_bytes),
    users: active_user_data
  }
end


# def get_active_hotspot_users
#   nas_router = NasRouter.find_by(name: params[:router_name]) || NasRouter.find_by(name: ActsAsTenant.current_tenant.router_setting)
#   return render json: { error: 'Router not found' }, status: :not_found unless nas_router

#   router_ip_address = nas_router.ip_address
#   router_password = nas_router.password
#   router_username = nas_router.username



#   uri = URI("http://#{router_ip_address}/rest/ip/hotspot/active")
#   request = Net::HTTP::Get.new(uri)
#   request.basic_auth router_username, router_password
#   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#     http.request(request)
#   end

#   if response.is_a?(Net::HTTPSuccess) 
#     json_response = JSON.parse(response.body)
#     active_user_data = customize_router_data(json_response)
#     # Rails.logger.info "Active Hotspot Users: #{json_response['user']}"
#     render json: active_user_data
#   end

# end



# def get_active_hotspot_users
#   nas_router = NasRouter.find_by(name: params[:router_name]) || NasRouter.find_by(name: ActsAsTenant.current_tenant.router_setting)
#   return render json: { error: 'Router not found' }, status: :not_found unless nas_router

#   router_ip_address = nas_router.ip_address
#   router_password = nas_router.password
#   router_username = nas_router.username

#   uri = URI("http://#{router_ip_address}/rest/ip/hotspot/active")
#   request = Net::HTTP::Get.new(uri)
#   request.basic_auth router_username, router_password
#   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#     http.request(request)
#   end

#   if response.is_a?(Net::HTTPSuccess) 
#     json_response = JSON.parse(response.body)
#     active_user_data = customize_router_data(json_response)

#     # Add the count of active users
#     active_user_count = active_user_data.size

#     render json: { active_user_count: active_user_count, users: active_user_data }
#   else
#     render json: { error: 'Failed to fetch active users' }, status: :bad_gateway
#   end
# end


  # DELETE /hotspot_subscriptions/1 or /hotspot_subscriptions/1.json
  def destroy
    @hotspot_subscription.destroy!

    respond_to do |format|
      format.html { redirect_to hotspot_subscriptions_path, status: :see_other, notice: "Hotspot subscription was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_subscription
      @hotspot_subscription = HotspotSubscription.find(params[:id])
    end


    def format_uptime(seconds)
  return '0s' if seconds.nil?

  mm, ss = seconds.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)

  parts = []
  parts << "#{dd}d" if dd > 0
  parts << "#{hh}h" if hh > 0
  parts << "#{mm}m" if mm > 0
  parts << "#{ss}s"
  parts.join(' ')
    end
    # def customize_router_data(data_array)
    #   data_array.map do |data|
    #     {
    #       id: data[".id"],
    #       voucher: data["user"],
    #       ip_address: data["address"],
    #       mac_address: data["mac-address"],
    #       up_time: data["uptime"],
    #       idle_time: data["idle-time"],
    #       download: format_bytes(data['bytes-in'].to_i),
    #       upload: format_bytes(data['bytes-out'].to_i),
    #       packets_in: data['packets-in'].to_i,
    #       packets_out: data['packets-out'].to_i,
    #       server: data['server'],
    #       login_by: data['login-by'],
    #       radius: data['radius'] == 'true'
    #     }
    #   end
    # end
   
    def format_bytes(bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      return '0 B' if bytes.zero?
    
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      size = bytes / (1024.0**exp)
      "%.2f #{units[exp]}" % size
    
    
  end
    # Only allow a list of trusted parameters through.
    def hotspot_subscription_params
      params.require(:hotspot_subscription).permit(:voucher, :ip_address, :start_time, :up_time, :download, :upload, :account_id)
    end
end
