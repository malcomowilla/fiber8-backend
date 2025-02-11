


class SubscriberTicketMailer < ApplicationMailer

  def send_ticket(ticket_number, ticket_created_at, 
    subscriber_email, issue_description, ticket_status, ticket_priority,
    customer_code, customer_portal_link, company_name, customer_support_email)
  
  
    @ticket_priority = ticket_priority
    @ticket_status = ticket_status
    @subscriber_email = subscriber_email
    @ticket_number = ticket_number
    @ticket_created_at = ticket_created_at
    @issue_description = issue_description
    @customer_code = customer_code
    @customer_portal_link = customer_portal_link
    @company_name = company_name
    @customer_support_email = customer_support_email
    @tracking_url = "http://#{customer_portal_link}/customer_role"
  
  
  #   template_uuid = ENV['MAIL_TRAP_CUSTOMER_TICKETS']
  
  #   if template_uuid.nil? 
  #     Rails.logger.error "template uuid is nil"
  # end
  
    # MailtrapService.new(ENV['MAIL_TRAP_API_KEY']).send_template_email(
    #   to: @customer_email,
    #   template_uuid: template_uuid,
    #   template_variables: {
        
    #     "customer_email" => @customer_email,
    #      "ticket_created_at" => @ticket_created_at,
    #      "ticket_number" => @ticket_number,
    #      "issue_description" => @issue_description,
    #      "ticket_status" => @ticket_status,
    #      "ticket_priority" => @ticket_priority,
    #      "customer_portal_link" => "https://#{@customer_portal_link}/customer_role?my_customer_code=#{@customer_code}"
        
    #   }
    # )
    # 
    #
    #
    #
    
  mail(
    from: tenant_sender_email,  
    to: @subscriber_email,
    subject: 'Your Subscriber Ticket',
    category: 'Subscriber Ticket',
    
  )
  end
end


































