


class HotspotChannel < ApplicationCable::Channel
  def subscribed
    subdomain = params["X-Subdomain"]
    ip = params["X-ip"]
    session = TemporarySession.find_by(ip: ip)
    account = Account.find_by(subdomain: subdomain)

    if account
      ActsAsTenant.current_tenant = account
      stream_for account
    else
      reject
    end
  end
 
def unsubscribed
    ActsAsTenant.current_tenant = nil
  end
end


