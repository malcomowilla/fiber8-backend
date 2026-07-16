class HotspotSessionsController < ApplicationController
  


  set_current_tenant_through_filter

  before_action :set_tenant









  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end






  # Add these actions to your HotspotSessionsController
# Also add to your routes:
#
#   get  'hotspot_sessions/free_trial_devices', to: 'hotspot_sessions#free_trial_devices'
#   delete 'hotspot_sessions/free_trial_devices/:id', to: 'hotspot_sessions#destroy_free_trial_device'
#
# The existing logout_user action already handles MAC-based logout,
# but we add a mac param path so the React component can call it directly.

# GET /hotspot_sessions/free_trial_devices
def free_trial_devices
  devices = FreeTrialDevice.where(account_id: @account.id)
                           .order(used_at: :desc)

  render json: devices.map { |d|
    {
      id:          d.id,
      mac_address: d.mac_address,
      package:     d.package,
      used_at:     d.used_at
    }
  }
end

# DELETE /hotspot_sessions/free_trial_devices/:id
def destroy_free_trial_device
  device = FreeTrialDevice.find_by!(id: params[:id], account_id: @account.id)
  device.destroy!

  # Also remove the RADIUS entries so the MAC cannot re-auth on the old group
  RadUserGroup.where(username: device.mac_address).destroy_all
  RadCheck.where(username: device.mac_address, account_id: @account.id).destroy_all

  render json: { message: 'Device record deleted' }, status: :ok

rescue ActiveRecord::RecordNotFound
  render json: { error: 'Device not found' }, status: :not_found
end



def logout_user
  host    = request.headers['X-Subdomain']
  @account = Account.find_by!(subdomain: host)

  # Support both voucher-based and MAC-based logout
  mac     = params[:mac]
  voucher = params[:voucher]

  if mac.present?
    username    = mac.upcase
    nas_routers = NasRouter.where(account_id: @account.id)
  elsif voucher.present?
    hotspot_voucher = HotspotVoucher.find_by(voucher: voucher)
    return render json: { error: 'Voucher not found' }, status: :not_found unless hotspot_voucher
    username    = hotspot_voucher.voucher
    nas_routers = NasRouter.where(account_id: hotspot_voucher.account_id)
  else
    return render json: { error: 'mac or voucher param required' }, status: :unprocessable_entity
  end

  nas_routers.each do |nas|
    begin
      active_users = RestClient::Request.execute(
        method:   :get,
        url:      "http://#{nas.ip_address}/rest/ip/hotspot/active",
        user:     nas.username,
        password: nas.password
      )

      users  = JSON.parse(active_users.body)
      active = users.find { |u| u['user'] == username }
      next unless active

      RestClient::Request.execute(
        method:   :post,
        url:      "http://#{nas.ip_address}/rest/ip/hotspot/active/remove",
        user:     nas.username,
        password: nas.password,
        payload:  { '.id': active['.id'] }.to_json,
        headers:  { content_type: :json }
      )

      if hotspot_voucher
        HotspotVoucherChannel.broadcast_to(@account, {
          type:      'voucher_online',
          is_online: false,
          voucher:   hotspot_voucher,
          id:        hotspot_voucher.id
        })
      end

      return render json: { message: 'Successfully logged out user' }, status: :ok

    rescue RestClient::Unauthorized
      Rails.logger.info "REST auth failed for router #{nas.ip_address}"
      next
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"
      next
    rescue StandardError => e
      Rails.logger.info "REST error logging out device #{nas.ip_address}: #{e.message}"
      next
    end
  end

  render json: { error: 'User not found on any router' }, status: :not_found
end



def grant_free_trial
  mac     = params[:mac]
  ip      = params[:ip]
  package = params[:package]
  host    = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)

  hotspot_package = HotspotPackage.find_by(name: package, account_id: @account.id)
  return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package

  free_trial_duration_minutes = hotspot_package.free_trial_duration_minutes

  existing = FreeTrialDevice.find_by(mac_address: mac.upcase, account_id: @account.id)

  if existing
    return render json: {
      error: "Free trial already used on this device"
    }, status: :unprocessable_entity
  end

  # ── Branch on whether this account authenticates through RADIUS or
  # talks to the router natively. Writing RadCheck/RadUserGroup rows does
  # nothing for a native account — there's no FreeRADIUS server sitting in
  # front of the router to consult them, so the MAC would never actually
  # be authorized. Mirrors the same split used for vouchers
  # (create_voucher_radcheck vs sync_voucher_natively).
  if router_uses_radius?
    free_trial_radius(mac, package, @account.id, free_trial_duration_minutes)
  else
    free_trial_native(mac, hotspot_package, @account.id, free_trial_duration_minutes)
  end

  FreeTrialDevice.create!(
    mac_address: mac.upcase,
    package: package,
    used_at: Time.current
  )

  nas = NasRouter.find_by(name: hotspot_package.nas_router, account_id: @account.id)
  return render json: { error: 'No router configured for this package' }, status: :unprocessable_entity unless nas

  begin
    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
      user: nas.username,
      password: nas.password,
      payload: {
        ip: ip,
        user: mac,
        password: mac
      }.to_json,
      headers: {
        content_type: :json,
        accept: :json
      }
    )

    if response.code == 200
      return render json: {
        message: 'Connected successfully',
        device_ip: ip,
        username: mac,
      }, status: :ok
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error (#{nas.ip_address}): #{e.response}"

  rescue StandardError => e
    Rails.logger.info "REST login error: #{e.message}"
  end

  render json: { error: 'Failed to connect, please try again' }, status: :unprocessable_entity
end










def free_trial_radius(mac, package, account_id, free_trial_duration_minutes)

 group_name = "freetrial_#{account_id}_#{package.parameterize(separator: '_')}"

rad_user_group = RadUserGroup.find_or_initialize_by(username: mac.upcase,
 groupname: group_name, account_id: account_id)



rad_user_group.update!(username: mac.upcase, groupname: group_name)





macupcase = mac.upcase
radcheck = RadCheck.find_or_initialize_by(username: macupcase,
account_id: account_id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: macupcase)
end



# ── Native MikroTik equivalent of free_trial_radius. Instead of writing
# RadCheck/RadUserGroup rows (which only get consulted by a RADIUS
# server), this pushes a temporary hotspot user straight onto the
# router itself, keyed by MAC, with limit-uptime capped to the trial
# duration so it auto-expires on the router side too. Same request
# shape as sync_voucher_natively.
def free_trial_native(mac, hotspot_package, account_id, free_trial_duration_minutes)
  nas = NasRouter.find_by(name: hotspot_package.nas_router, account_id: account_id) 

  unless nas
    Rails.logger.info "free_trial_native: no router found for account #{account_id}"
    return
  end

  macupcase = mac.upcase
  minutes = free_trial_duration_minutes.to_i
  minutes = 1 if minutes < 1

  begin
    RestClient::Request.execute(
      method: :put,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
      user: nas.username.to_s,
      password: nas.password.to_s,
      payload: {
        name: macupcase,
        password: macupcase,
        profile: hotspot_package.name,
        "limit-uptime": "#{minutes}m",
        comment: "free_trial"
      }.to_json,
      headers: { content_type: :json },
      timeout: 10
    )
  rescue RestClient::Unauthorized
    Rails.logger.info "free_trial_native: REST auth failed for router #{nas.ip_address}"
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "free_trial_native: MikroTik REST error on #{nas.ip_address}: #{e.response}"
  rescue StandardError => e
    Rails.logger.info "free_trial_native: REST error on #{nas.ip_address}: #{e.message}"
  end
end



private

def router_uses_radius?
  setting = NasSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
  setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
end

end