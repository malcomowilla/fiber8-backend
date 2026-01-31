

class SubscriberChannel < ApplicationCable::Channel
  def subscribed
    subdomain = params["X-Subdomain"]
    account = Account.find_by(subdomain: subdomain)
    subscriber_id = params["X-SubscriberId"]

    if subscriber_id
      ActsAsTenant.current_tenant = account
      stream_for  subscriber_id

    else
      reject
    end
  end

  def unsubscribed
    ActsAsTenant.current_tenant = nil
  end


  
end


