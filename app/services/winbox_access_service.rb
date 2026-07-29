# app/services/winbox_access_service.rb
#
# Grants temporary WinBox access by adding the VPS's WireGuard address to a
# `winbox-temp` address-list entry on the MikroTik, using the router's REST
# API — same RestClient pattern used everywhere else in this app
# (sync_voucher_natively, get_active_sessions, login_with_hotspot_voucher).
# RouterOS expires the address-list entry itself once the timeout elapses,
# so there's no teardown job to run.
#
# One-time manual setup per router (in WinBox/terminal, not done here):
#
#   /ip firewall filter add chain=input protocol=tcp dst-port=8291 \
#     src-address-list=winbox-temp action=accept comment=winbox-temp-access
#
# And on the VPS, a single static (never added/removed) relay rule:
#
#   iptables -t nat -A PREROUTING -p tcp --dport <static_relay_port> \
#     -j DNAT --to-destination <router_wg_ip>:8291
#   iptables -t nat -A POSTROUTING -p tcp -d <router_wg_ip> --dport 8291 \
#     -j MASQUERADE

class WinboxAccessService
  ADDRESS_LIST = 'winbox-temp'
  ACCESS_DURATION = '15m'

  def initialize(nas_router)
    @nas_router = nas_router
  end

  # Returns { success: true, expires_at: Time } or { success: false, error: String }
  def grant_temporary_access
    vps_wg_address = ENV['VPS_WIREGUARD_ADDRESS']
    if vps_wg_address.blank?
      return { success: false, error: 'Server misconfiguration: VPS_WIREGUARD_ADDRESS not set' }
    end

    RestClient::Request.execute(
      method: :put,
      url: "http://#{@nas_router.ip_address}/rest/ip/firewall/address-list",
      user: @nas_router.username,
      password: @nas_router.password,
      payload: {
        list: ADDRESS_LIST,
        address: vps_wg_address,
        timeout: ACCESS_DURATION,
        comment: 'remote-winbox-session'
      }.to_json,
      headers: { content_type: :json },
      timeout: 5,
      open_timeout: 3
    )

    { success: true, expires_at: 15.minutes.from_now }

  rescue RestClient::Unauthorized
    Rails.logger.error "[WinBox access] REST auth failed for router #{@nas_router.id}"
    { success: false, error: 'Router authentication failed' }

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "[WinBox access] MikroTik REST error on #{@nas_router.ip_address}: #{e.response}"
    { success: false, error: 'Router rejected the request' }

  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
    Rails.logger.error "[WinBox access] Router #{@nas_router.ip_address} timed out"
    { success: false, error: 'Router timed out' }

  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    Rails.logger.error "[WinBox access] Router #{@nas_router.ip_address} unreachable: #{e.message}"
    { success: false, error: 'Router unreachable' }

  rescue StandardError => e
    Rails.logger.error "[WinBox access] Failed for router #{@nas_router.id}: #{e.message}"
    { success: false, error: 'Could not reach router API' }
  end
end