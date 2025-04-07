class SendSmsController < ApplicationController
  require 'net/http'
  require 'json'
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

  require 'message_template'

  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

def send_sms
  provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
  case provider
    when 'TextSms'
      send_sms_text_sms
    when 'SMS leopard'
      send_sms_sms_leopard
    else
      render json: { error: "No valid SMS provider configured" }, status: :unprocessable_entity
      return
  end

end




  def send_sms_text_sms
    to = params[:to]
    subject = params[:subject]
    message = params[:message]

    # 👉 Fetch subscriber details to replace placeholders
    subscriber = Subscriber.find_by(name: to)

    if subscriber.nil?
      render json: { error: 'Subscriber not found' }, status: :not_found
      return
    end

    # 👇 Replace placeholders like {{name}}, {{email}}, etc.
    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
    })

    # ✅ Send SMS (you can reuse your existing method or simplify here)
    sms_setting = SmsSetting.find_by(sms_provider: 'TEXT_SMS')

    if sms_setting.nil?
      render json: { error: "SMS provider not found" }, status: :not_found
      return
    end

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    sms_params = {
      apikey: sms_setting.api_key,
      message: interpolated_message,
      mobile: subscriber.phone_number,
      partnerID: sms_setting.partnerID,
      shortcode: 'TextSMS'
    }
    uri.query = URI.encode_www_form(sms_params)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body)
      if body.dig('responses', 0, 'respose-code') == 200
        sms_data = JSON.parse(response.body)
        sms_status = sms_data['responses'][0]['response-description']
    
        sms_recipient = subscriber.name # or subscriber.id if `user` expects an ID
        SystemAdminSm.create!(
          user: sms_recipient,
          message: interpolated_message,
          status: sms_status,
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
          system_user: 'system',
          sms_provider: 'TextSms'

        )
        render json: { success: true, message: 'SMS sent successfully' }, status: :ok
      else
        render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      render json: { error: response.body }, status: :internal_server_error
    end
  end





  def send_sms_sms_leopard
    to = params[:to]
    subject = params[:subject]
    message = params[:message]

    # 👉 Fetch subscriber details to replace placeholders
    subscriber = Subscriber.find_by(name: to)

    if subscriber.nil?
      render json: { error: 'Subscriber not found' }, status: :not_found
      return
    end

    # 👇 Replace placeholders like {{name}}, {{email}}, etc.
    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
    })

    # ✅ Send SMS (you can reuse your existing method or simplify here)
    sms_setting = SmsSetting.find_by(sms_provider: 'SMS leopard')

    if sms_setting.nil?
      render json: { error: "SMS provider not found" }, status: :not_found
      return
    end









    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    sms_params = {
      username: sms_setting&.api_key,
      message: interpolated_message,
      destination: subscriber&.phone_number,
      password: sms_setting&.api_secret,
      source: "SMS_TEST",
      
    }
    uri.query = URI.encode_www_form(sms_params)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body)
      if body.dig('responses', 0, 'respose-code') == 200
        sms_data = JSON.parse(response.body)
        sms_status = sms_data['responses'][0]['response-description']
    
        sms_recipient = subscriber.name # or subscriber.id if `user` expects an ID
        SystemAdminSm.create!(
          user: sms_recipient,
          message: interpolated_message,
          status: sms_status,
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
          system_user: 'system',
          sms_provider: 'SMS leopard'

        )
        render json: { success: true, message: 'SMS sent successfully' }, status: :ok
      else
        render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      render json: { error: response.body }, status: :internal_server_error
    end
  end


















end
