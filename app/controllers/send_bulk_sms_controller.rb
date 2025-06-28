




class SendBulkSmsController < ApplicationController
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
    return render json: { error: 'Invalid tenant' }, status: :not_found
  end

def send_sms
  provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
 
  
  if params[:status] === 'all clients' && params[:strict_filter] === 'false' || params[:strict_filter] === false
      return render json: { error: "No valid SMS provider configured" }, status: :unprocessable_entity if provider.nil?

       case provider
    when 'TextSms'
      send_sms_text_sms
    when 'SMS leopard'
      send_sms_sms_leopard
   
  end


    elsif params[:strict_filter] === 'true' || params[:strict_filter] === true

       case provider
    when 'TextSms'
      send_sms_text_sms_locations
    when 'SMS leopard'
      send_sms_sms_leopard_locations
   
  end




  end





end



def send_sms_text_sms_locations

  subcriber = Subscriber.where(
     "location && ARRAY[?]::text[]",
      params[:locations]
  )

    subscribers = subcriber.all

        subscribers.each do |subscriber|
          

    message = params[:message]
Rails.logger.info "message: #{message}"
    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
      phone: subscriber.phone_number,
      email: subscriber.email,


    })

    sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

    # if sms_setting.nil?
    #   return render json: { error: "SMS provider not found" }, status: :not_found
    # end
  return { error: "SMS provider not found" } if sms_setting.nil?

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
      Rails.logger.info "Response sent message: #{body}"
      Rails.logger.info "Failed to send message body: #{body.dig('responses', 0, 'response-code')}"

      if body.dig('responses', 0, 'response-code') == 200
        sms_data = JSON.parse(response.body)
        sms_status = sms_data['responses'][0]['response-description']

    Rails.logger.info "SMS Status: #{sms_status}"
        sms_recipient = subscriber.name # or subscriber.id if `user` expects an ID
        SystemAdminSm.create!(
          user: sms_recipient,
          message: interpolated_message,
          status: body.dig('responses', 0, 'response-description'),
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
          system_user: current_user.username,
          sms_provider: 'TextSms'

        )
        Rails.logger.info "ody message sent: #{body}"
         return render json: { success: true, message: 'SMS sent successfully' }
      else
        Rails.logger.info "Failed to send message//eror response but message sent: #{body.dig('responses', 0, 'response-description')}"
        return render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
      return render json: { error: response.body }, status: :internal_server_error
    end
        end

  end



 def send_sms_sms_leopard_locations

  subcriber = Subscriber.where(
     "location && ARRAY[?]::text[]",
      params[:locations]
  )

    subscribers = subcriber.all
        subscribers.each do |subscriber|
    message = params[:message]

    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
      phone: subscriber.phone_number,
      email: subscriber.email,


    })
   
    # ✅ Send SMS (you can reuse your existing method or simplify here)
    sms_setting = SmsSetting.find_by(sms_provider: 'SMS leopard')

    if sms_setting.nil?
      return render json: { error: "SMS provider not found" }, status: :not_found
      
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
          system_user: current_user.username,
          sms_provider: 'SMS leopard'

        )
        return render json: { success: true, message: 'SMS sent successfully' }, status: :ok
      else
        return render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      return render json: { error: response.body }, status: :internal_server_error
    end
  end
  end



  def send_sms_text_sms
        subscribers = Subscriber.all
        subscribers.each do |subscriber|
          

    message = params[:message]
Rails.logger.info "message: #{message}"
    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
      phone: subscriber.phone_number,
      email: subscriber.email,


    })

    sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

    # if sms_setting.nil?
    #   return render json: { error: "SMS provider not found" }, status: :not_found
    # end
  return { error: "SMS provider not found" } if sms_setting.nil?

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
      Rails.logger.info "Response sent message: #{body}"
      Rails.logger.info "Failed to send message body: #{body.dig('responses', 0, 'response-code')}"

      if body.dig('responses', 0, 'response-code') == 200
        sms_data = JSON.parse(response.body)
        sms_status = sms_data['responses'][0]['response-description']

    Rails.logger.info "SMS Status: #{sms_status}"
        sms_recipient = subscriber.name # or subscriber.id if `user` expects an ID
        SystemAdminSm.create!(
          user: sms_recipient,
          message: interpolated_message,
          status: body.dig('responses', 0, 'response-description'),
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
          system_user: current_user.username,
          sms_provider: 'TextSms'

        )
        Rails.logger.info "ody message sent: #{body}"
         return render json: { success: true, message: 'SMS sent successfully' }
      else
        Rails.logger.info "Failed to send message//eror response but message sent: #{body.dig('responses', 0, 'response-description')}"
        return render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
      return render json: { error: response.body }, status: :internal_server_error
    end
        end

  end





  def send_sms_sms_leopard
     subscribers = Subscriber.all
        subscribers.each do |subscriber|
    message = params[:message]

    interpolated_message = MessageTemplate.interpolate(message, {
      name: subscriber.name,
      phone: subscriber.phone_number,
      email: subscriber.email,


    })
   
    # ✅ Send SMS (you can reuse your existing method or simplify here)
    sms_setting = SmsSetting.find_by(sms_provider: 'SMS leopard')

    if sms_setting.nil?
      return render json: { error: "SMS provider not found" }, status: :not_found
      
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
          system_user: current_user.username,
          sms_provider: 'SMS leopard'

        )
        return render json: { success: true, message: 'SMS sent successfully' }, status: :ok
      else
        return render json: { error: body.dig('responses', 0, 'response-description') }, status: :bad_request
      end
    else
      return render json: { error: response.body }, status: :internal_server_error
    end
  end
  end


















end
