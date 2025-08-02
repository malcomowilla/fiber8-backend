


class HotspotChannel < ApplicationCable::Channel
  def subscribed
    subdomain = params["X-Subdomain"]
    account = Account.find_by(subdomain: subdomain)

    if account
      ActsAsTenant.current_tenant = account
      stream_for account
    else
      reject
    end 
  end
end


