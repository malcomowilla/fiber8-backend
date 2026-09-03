class HotspotPaymentsChannel < ApplicationCable::Channel
  def subscribed
    subdomain = params['X-Subdomain']
    account = Account.find_by(subdomain: subdomain)

    if account
      stream_from "hotspot_payments_#{account.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end