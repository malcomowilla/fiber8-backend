

class HotspotNotificationsChannel < ApplicationCable::Channel
  def subscribed
    ip = params["X-ip"]
    subdomain = params["X-Subdomain"]
    # session = TemporarySession.find_by(ip: ip)
    # account = Account.find_by(subdomain: subdomain)

    if session 
      # ActsAsTenant.current_tenant = account
      stream_for session.ip
    else
      reject
    end
  end

end