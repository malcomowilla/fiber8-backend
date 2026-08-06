# app/controllers/concerns/hotspot_voucher_provisioning.rb
module HotspotVoucherProvisioning
  extend ActiveSupport::Concern

  def provision_voucher(hotspot_package, voucher, account_id)
    voucher_expiration_mode = HotspotSetting.find_by(account_id: account_id)&.voucher_expiration
    use_radius = router_uses_radius_for(account_id)

    calculate_expiration_login_with_voucher(hotspot_package, voucher, account_id)

    if use_radius
      if voucher_expiration_mode == 'Real-time expiration'
        create_voucher_radcheck(voucher.voucher, hotspot_package.name, account_id)
      else
        create_voucher_radcheck_accumulated_sessions(voucher.voucher, hotspot_package.name, account_id)
      end
    else
      if voucher_expiration_mode == 'Real-time expiration'
        sync_voucher_natively(voucher)
      else
        sync_voucher_natively_realtime_expiration(voucher)
      end
    end
  end

  def router_uses_radius_for(account_id)
    setting = NasSetting.find_by(account_id: account_id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end

  def calculate_expiration_login_with_voucher(hotspot_package, voucher_created, account_id)
    return unless hotspot_package
    expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
      case hotspot_package.validity_period_units.downcase
      when 'days' then Time.current + hotspot_package.validity.days
      when 'hours' then Time.current + hotspot_package.validity.hours
      when 'minutes' then Time.current + hotspot_package.validity.minutes
      end
    end
    voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p")) if expiration_time
  end

  def create_voucher_radcheck(hotspot_voucher, package, account_id)
    group = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"

    radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher, account_id: account_id, radiusattribute: 'Cleartext-Password')
    radcheck.update!(op: ':=', value: hotspot_voucher)

    rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher, groupname: group, priority: 1, account_id: account_id)
    rad_user_group.update!(username: hotspot_voucher, groupname: group, priority: 1)

    pkg = HotspotPackage.find_by(name: package, account_id: account_id)
    return unless pkg

    expiration_time = case pkg.validity_period_units
      when 'days' then Time.current + pkg.validity.days
      when 'hours' then Time.current + pkg.validity.hours
      when 'minutes' then Time.current + pkg.validity.minutes
    end&.strftime("%d %b %Y %H:%M:%S")

    if expiration_time
      rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher, account_id: account_id, radiusattribute: 'Expiration')
      rad_check.update!(op: ':=', value: expiration_time)
    end
  end

  def create_voucher_radcheck_accumulated_sessions(hotspot_voucher, package, account_id)
    group = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"

    radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher, account_id: account_id, radiusattribute: 'Cleartext-Password')
    radcheck.update!(op: ':=', value: hotspot_voucher)

    rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher, groupname: group, priority: 1, account_id: account_id)
    rad_user_group.update!(username: hotspot_voucher, groupname: group, priority: 1)

    pkg = HotspotPackage.find_by(name: package, account_id: account_id)
    return unless pkg

    seconds = case pkg.validity_period_units
      when "minutes" then pkg.validity.minutes.to_i
      when "hours" then pkg.validity.hours.to_i
      when "days" then pkg.validity.days.to_i
    end

    if seconds
      rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher, account_id: account_id, radiusattribute: 'Max-All-Session')
      rad_check.update!(op: ':=', value: seconds)
    end
  end

  def sync_voucher_natively(voucher)
    package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

    nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

    begin
      RestClient::Request.execute(
        method: :put,
        url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
        user: nas.username.to_s, password: nas.password.to_s,
        payload: { name: voucher.voucher, password: voucher.voucher, profile: package.name }.to_json,
        headers: { content_type: :json }, timeout: 10
      )
      voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
    rescue => e
      voucher.update(sync_status: 'failed', sync_error: e.message)
    end
  end

  def sync_voucher_natively_realtime_expiration(voucher)
    package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

    nas = NasRouter.find_by(name: package.nas_router)
    return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

    begin
      RestClient::Request.execute(
        method: :put,
        url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
        user: nas.username.to_s, password: nas.password.to_s,
        payload: { name: voucher.voucher, password: voucher.voucher, profile: package.name,
                   "limit-uptime": validity_for_mikrotik(package) }.to_json,
        headers: { content_type: :json }, timeout: 10
      )
      voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
    rescue => e
      voucher.update(sync_status: 'failed', sync_error: e.message)
    end
  end

  def validity_for_mikrotik(pkg)
    case pkg.validity_period_units
    when "minutes" then "#{pkg.validity}m"
    when "hours" then "#{pkg.validity}h"
    when "days" then "#{pkg.validity}d"
    when "weeks" then "#{pkg.validity}w"
    else "0s"
    end
  end
end