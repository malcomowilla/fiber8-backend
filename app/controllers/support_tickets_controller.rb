class SupportTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  load_and_authorize_resource

  before_action :update_last_activity
  before_action :set_time_zone




   def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end


  def set_tenant
  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
  ActsAsTenant.current_tenant = @account
  EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])

  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  end







  def index
    @support_tickets = SupportTicket.all
    render json: @support_tickets
  end

  

  def total_tickets
    total_tickets = SupportTicket.count
    render json: { total_tickets: total_tickets }
  end
    
  def open_tickets
    open_tickets = SupportTicket.where(status: 'Open').count
    render json: { open_tickets: open_tickets }
  end


  def solved_tickets
    solved_tickets = SupportTicket.where(status: 'Resolved').count
    render json: { solved_tickets: solved_tickets }
    
  end


  def high_priority_tickets
    high_priority_tickets = SupportTicket.where(priority: 'Urgent').count
    render json: { high_priority_tickets: high_priority_tickets }
    
  end


def get_specific_ticket
  customer_code = Customer.find_by(customer_code: params[:my_customer_code])
end


def create
  @support_ticket = SupportTicket.new(support_ticket_params)

  if @support_ticket.valid?
    tenant = ActsAsTenant.current_tenant
    ticket_setting = tenant&.ticket_setting

    # unless ticket_setting && ticket_setting.prefix.present? && ticket_setting.minimum_digits.present?
    #   return render json: { error: "Please create a ticket number for the account" }, status: :unprocessable_entity
    # end



    prefix = ticket_setting&.prefix
    minimum_digits = ticket_setting&.minimum_digits

    @support_ticket.save!
    Rails.logger.info "support ticket info after save: #{@support_ticket.inspect}"

    ActivtyLog.create(
      action: 'create',
      ip: request.remote_ip,
      description: "Created support ticket #{@support_ticket.ticket_number}",
      user_agent: request.user_agent,
      user: current_user.username || current_user.email,
      date: Time.current
    )

    auto_generated_number = "#{prefix}#{@support_ticket.sequence_number.to_s.rjust(minimum_digits.to_i, '0')}"

    @support_ticket.update!(
      # ticket_number: auto_generated_number,
      ticket_number: (prefix.blank? || minimum_digits.blank?) ? SecureRandom.hex(2) : auto_generated_number,

      date_of_creation: Time.now.strftime('%Y-%m-%d %I:%M:%S %p')
    )

    render json: @support_ticket, status: :created
  else
    render json: @support_ticket.errors, status: :unprocessable_entity
  end
end


  def update
    support_ticket = SupportTicket.find_by(id: params[:id])
      if support_ticket.update(support_ticket_params)
        support_ticket.update(date_closed: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
        ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated support ticket #{@support_ticket.ticket_number}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
         render json: support_ticket, status: :ok
      else
         render json: support_ticket.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /support_tickets/1 or /support_tickets/1.json
  def destroy
    @support_ticket.destroy!
ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted support ticket #{@support_ticket.ticket_number}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
     head :no_content 
    
  end



  def send_ticket
    agent = params[:support_ticket][:agent]
    ticket_number = params[:support_ticket][:ticket_number]
    ticket_category = params[:support_ticket][:ticket_category]
    agent_review = params[:support_ticket][:agent_review]
    customer_name = params[:support_ticket][:customer_name]
    customer_phone = Subscriber.find_by(name: customer_name)&.phone_number



    agent_phone_number = User.find_by(username: agent)&.phone_number
     if ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == "SMS leopard"
              send_ticket_sms_leopard(agent_phone_number,ticket_number,ticket_category,
            agent_review,customer_phone, customer_name
        )
               
             elsif ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == "TextSms"
              send_ticket_text_sms(agent_phone_number,ticket_number,ticket_category,
            agent_review,customer_phone,customer_name
            )
             end
  end

  private
    # Use callbacks to share common setup or constraints between actions.





       def send_ticket_sms_leopard(agent_phone_number,ticket_number,ticket_category,
            agent_review,customer_phone, customer_name
        )
      # api_key = ActsAsTenant.current_tenant.sms_setting.api_key
      # api_secret = ActsAsTenant.current_tenant.sms_setting.api_secret
      
      api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    
              api_key = api_key
              api_secret = api_secret
             
      
      
      sms_template =  ActsAsTenant.current_tenant.sms_template
      send_voucher_template = sms_template&.send_voucher_template
    #   original_message = sms_template ?  MessageTemplate.interpolate(send_voucher_template,{
        
    #   voucher_code: voucher_code,
    #   voucher_expiration: voucher_expiration

    #   })  :   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
    #  Enjoy your browsing"
              original_message = "Support Ticket
  Ticket No: #{ticket_number}
Issue: #{ticket_category}
Agent Review: #{agent_review}
Customer Contact:  #{customer_phone}
Custimer Name: #{customer_name}

Please investigate and resolve.
 .
  #"
      
              sender_id = "SMS_TEST" # Ensure this is a valid sender ID
          
              uri = URI("https://api.smsleopard.com/v1/sms/send")
              params = {
                username: api_key,
                password: api_secret,
                message: original_message,
                destination: phone_number,
                source: sender_id
              }
              uri.query = URI.encode_www_form(params)
          
              response = Net::HTTP.get_response(uri)
              if response.is_a?(Net::HTTPSuccess)
                sms_data = JSON.parse(response.body)
            
                if sms_data['success']
                  sms_recipient = sms_data['recipients'][0]['number']
                  sms_status = sms_data['recipients'][0]['status']
                  
                  puts "Recipient: #{sms_recipient}, Status: #{sms_status}"
            
                  # Save the original message and response details in your database
                  SystemAdminSm.create!(
                    user: sms_recipient,
                    message: original_message,
                    status: sms_status,
                    date:Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
                    system_user: 'system'
                  )
                  
                  # Return a JSON response or whatever is appropriate for your application
                  render json: { message: "Message sent successfully", recipient: sms_recipient, status: sms_status }, status: :ok
                else
                  render json: { error: "Failed to send message: #{sms_data['message']}" }, status: :unprocessable_entity
                  Rails.logger.info "Failed to send message: #{sms_data['message']}"
                end
              else
                puts "Failed to send message: #{response.body}"
                # render json: { error: "Failed to send message: #{response.body}" }
              end
            end





           def send_ticket_text_sms(agent_phone_number,ticket_number,ticket_category,
            agent_review,customer_phone,customer_name
            )
  sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

  api_key = sms_setting&.api_key
  partnerID = sms_setting&.partnerID 

  sms_template = ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template

 

  original_message = "Support Ticket
  Ticket No: #{ticket_number}
Issue: #{ticket_category}
Agent Review: #{agent_review}
Customer Contact:  #{customer_phone}
Custimer Name: #{customer_name}

Please investigate and resolve.
 .
  #"
   
  uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
  params = {
    apikey: api_key,
    message: original_message,
    mobile: agent_phone_number,
    partnerID: partnerID,
    shortcode: 'TextSMS'
  }
  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)

    if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
      sms_recipient = sms_data['responses'][0]['mobile']
      sms_status = sms_data['responses'][0]['response-description']

      puts "Recipient: #{sms_recipient}, Status: #{sms_status}"

      # Save the message and response details in your database
      SystemAdminSm.create!(
        user: sms_recipient,
        message: original_message,
        status: sms_status,
        date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
        system_user: 'system'
      )
    else
   render json: { message: "Message sent successfully", recipient: sms_recipient, status: sms_status }, status: :ok

       Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
    end
  else
    puts "Failed to send message: #{response.body}"
    render json: { error: "Failed to send message: #{response.body}" }, status: :unprocessable_entity
  end
end





    def set_support_ticket
      @support_ticket = SupportTicket.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def support_ticket_params
      params.require(:support_ticket).permit(:issue_description, :status, :priority, :agent, :ticket_number,
       :customer, :name, :email, :phone_number, :date_created, :ticket_category, :date_of_creation, :date_closed,
        :agent_review, :agent_response)
    end
end




