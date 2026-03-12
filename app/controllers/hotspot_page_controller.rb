
class HotspotPageController < ApplicationController
  def data
    subdomain = request.headers["X-Subdomain"]
    account = Account.find_by(subdomain: subdomain)

    return render json: { error: "Account not found" }, status: :not_found unless account

    data = Rails.cache.fetch("hotspot_page_data_#{account.id}", expires_in: 5.minutes) do
      {
        templates: account.hotspot_templates,
        ads: account.ads,
        ad_settings: account.ad_setting,
        hotspot_settings: account.hotspot_setting,
        customization: account.hotspot_customization,
        # company: {
        #   company_name: account.company_name,
        #   contact_info: account.contact_info,
        #   email_info: account.email_info,
        #   logo_url: account.logo_url
        # }
      }
    end

    render json: data
  end
end