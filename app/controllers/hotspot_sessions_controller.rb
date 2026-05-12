

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






def grant_free_trial
  mac = params[:mac]
  ip  = params[:ip]
  package = params[:package]
  host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
nas_routers = NasRouter.where(account_id: @account.id)
free_trial_duration_minutes = HotspotPackage.find_by(name: params[:package]).free_trial_duration_minutes 
  free_trial_radius(mac, package, @account.id, free_trial_duration_minutes)




#  group_name = "freetrial_#{@account.id}_#{package.parameterize(separator: '_')}"


 existing = FreeTrialDevice.find_by(mac_address: mac.upcase,
  account_id: @account.id)

if existing
  return render json: {
    error: "Free trial already used on this device"
  }, status: :unprocessable_entity
end


FreeTrialDevice.create!(
  mac_address: mac.upcase,
  package: package,
  used_at: Time.current
)

nas_routers = NasRouter.where(account_id: @account.id)

  nas_routers.each do |router|
    begin
      response = RestClient::Request.execute(
        method: :post,
        url: "http://#{router.ip_address}/rest/ip/hotspot/active/login",
        user: router.username,
        password: router.password,
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
      Rails.logger.info "REST auth failed for router #{router.ip_address}"
      next

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info "MikroTik REST error (#{router.ip_address}): #{e.response}"
      next

    rescue StandardError => e
      Rails.logger.info "REST login error: #{e.message}"
      next
       

    end


    end





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









end