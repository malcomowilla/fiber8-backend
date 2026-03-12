
class HotspotPageController < ApplicationController
   def data
    subdomain = request.headers["X-Subdomain"]
    account = Account.find_by(subdomain: subdomain)

    return render json: { error: "Account not found" }, status: :not_found unless account

    data = Rails.cache.fetch("hotspot_page_data_#{account.id}", expires_in: 5.minutes) do
      {
        templates: account.hotspot_templates.as_json,
        ads: account.ads.as_json,
        ad_settings: account.ad_setting&.as_json,
        hotspot_settings: account.hotspot_setting&.as_json,
        customization: account.hotspot_customization&.as_json
      }
    end

    render json: data
  end
end