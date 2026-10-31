require 'net/http'

class AccessApplicationNotifyJob < ApplicationJob
  queue_as :default

  def perform(application_id)
    app = AccessApplication.find(application_id)
    message = "New ISP application: #{app.company_name} (#{app.subdomain}) by #{app.name}, " \
              "#{app.phone_number}. Review in System Admin > Access applications."

    ENV['APPLICATION_ALERT_PHONES'].to_s.split(',').map(&:strip).reject(&:blank?).each do |phone|
      uri = URI('https://sms.textsms.co.ke/api/services/sendsms')
      uri.query = URI.encode_www_form(
        apikey:    ENV['TEXTSMS_API_KEY'],
        partnerID: ENV['TEXTSMS_PARTNER_ID'],
        shortcode: ENV['TEXTSMS_SHORTCODE'],
        mobile:    phone,
        message:   message
      )
      res = Net::HTTP.get_response(uri)
      Rails.logger.info "Application alert SMS to #{phone}: #{res.code} #{res.body}"
    end
  end
end