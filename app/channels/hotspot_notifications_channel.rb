

class HotspotNotificationsChannel < ApplicationCable::Channel
  def subscribed
    ip = params["X-ip"]
    session = TemporarySession.find_by(ip: ip)
    # account = Account.find_by(subdomain: subdomain)

    if session 
      # ActsAsTenant.current_tenant = account
      stream_for session
    else
      reject
    end
  end

end