class SupportTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  load_and_authorize_resource except: [:allow_get_support_ticket]

  before_action :update_last_activity
  before_action :set_time_zone

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def index
    @support_tickets = SupportTicket.all.includes(:ticket_updates)
    render json: @support_tickets.as_json(include: { ticket_updates: {} })
  end

  def allow_get_support_ticket
    @support_tickets = SupportTicket.where(subscriber_id: params[:subscriber_id])
    render json: @support_tickets
  end

  def total_tickets
    render json: { total_tickets: SupportTicket.count }
  end

  def open_tickets
    render json: { open_tickets: SupportTicket.where(status: 'Open').count }
  end

  def solved_tickets
    render json: { solved_tickets: SupportTicket.where(status: 'Resolved').count }
  end

  def high_priority_tickets
    render json: { high_priority_tickets: SupportTicket.where(priority: 'Urgent').count }
  end

  def get_specific_ticket
    Customer.find_by(customer_code: params[:my_customer_code])
  end

  def create
    @support_ticket = SupportTicket.new(support_ticket_params)
    subscriber = Subscriber.find_by(name: @support_ticket.customer)
    @support_ticket.subscriber_id = subscriber&.id

    if @support_ticket.valid?
      tenant = ActsAsTenant.current_tenant
      ticket_setting = tenant&.ticket_setting
      prefix = ticket_setting&.prefix
      minimum_digits = ticket_setting&.minimum_digits

      @support_ticket.save!

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
      ActivtyLog.create(
        action: 'update', ip: request.remote_ip,
        description: "Updated support ticket #{support_ticket.ticket_number}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current
      )
      render json: support_ticket, status: :ok
    else
      render json: support_ticket.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @support_ticket.destroy!
    ActivtyLog.create(
      action: 'delete', ip: request.remote_ip,
      description: "Deleted support ticket #{@support_ticket.ticket_number}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current
    )
    head :no_content
  end

  def send_ticket
    agent = params[:support_ticket][:agent]
    ticket_number = params[:support_ticket][:ticket_number]
    ticket_category = params[:support_ticket][:ticket_category]
    agent_review = params[:support_ticket][:agent_review]
    customer_name = params[:support_ticket][:customer_name]

    @support_ticket = SupportTicket.find_by(ticket_number: ticket_number)
    return render json: { error: 'Ticket not found' }, status: :not_found unless @support_ticket

    customer_phone = Subscriber.find_by(name: customer_name)&.phone_number
    agent_phone_number = User.find_by(username: agent)&.phone_number
    portal_link = "https://#{ActsAsTenant.current_tenant.subdomain}.#{ENV['APP_DOMAIN']}/technician/tickets/#{@support_ticket.access_token}"

    case ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    when 'SMS leopard'
      send_ticket_sms_leopard(agent_phone_number, ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    when 'TextSms'
      send_ticket_text_sms(agent_phone_number, ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    end
  end

  private

  def build_ticket_message(ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    "Support Ticket ##{ticket_number}\n" \
    "Issue: #{ticket_category}\n" \
    "Customer: #{customer_name} (#{customer_phone})\n" \
    "Note: #{agent_review}\n\n" \
    "Update status/remarks here:\n#{portal_link}"
  end

  def send_ticket_sms_leopard(agent_phone_number, ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    original_message = build_ticket_message(ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    sender_id = "SMS_TEST"

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: original_message,
      destination: agent_phone_number,
      source: sender_id
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body)
      if sms_data['success']
        sms_recipient = sms_data['recipients'][0]['number']
        sms_status = sms_data['recipients'][0]['status']
        SystemAdminSm.create!(
          user: sms_recipient, message: original_message, status: sms_status,
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'), system_user: 'system'
        )
        render json: { message: "Message sent successfully", recipient: sms_recipient, status: sms_status }, status: :ok
      else
        render json: { error: "Failed to send message: #{sms_data['message']}" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Failed to send message: #{response.body}" }, status: :unprocessable_entity
    end
  end

  def send_ticket_text_sms(agent_phone_number, ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)
    sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')
    api_key = sms_setting&.api_key
    partnerID = sms_setting&.partnerID
    original_message = build_ticket_message(ticket_number, ticket_category, agent_review, customer_phone, customer_name, portal_link)

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key, message: original_message, mobile: agent_phone_number,
      partnerID: partnerID, shortcode: 'TextSMS'
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body)
      if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
        sms_recipient = sms_data['responses'][0]['mobile']
        sms_status = sms_data['responses'][0]['response-description']
        SystemAdminSm.create!(
          user: sms_recipient, message: original_message, status: sms_status,
          date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'), system_user: 'system'
        )
        render json: { message: "Message sent successfully", recipient: sms_recipient, status: sms_status }, status: :ok
      else
        render json: { error: "Failed to send message: #{sms_data['responses'][0]['response-description']}" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Failed to send message: #{response.body}" }, status: :unprocessable_entity
    end
  end

  def set_support_ticket
    @support_ticket = SupportTicket.find_by(id: params[:id])
  end

  def support_ticket_params
    params.require(:support_ticket).permit(:issue_description, :status, :priority, :agent, :ticket_number,
      :customer, :name, :email, :phone_number, :date_created, :ticket_category, :date_of_creation, :date_closed,
      :agent_review, :agent_response)
  end
end