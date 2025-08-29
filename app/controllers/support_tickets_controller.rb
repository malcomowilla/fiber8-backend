class SupportTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  load_and_authorize_resource

  before_action :update_last_activity





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







# before_action :set_tenant 
# set_current_tenant_through_filter

   



# def set_tenant
#   @account = Account.find_or_create_by(subdomain: request.headers['X-Original-Host'])

#   set_current_tenant(@account)
# rescue ActiveRecord::RecordNotFound
#   render json: { error: 'Invalid tenant' }, status: :not_found
# end

  # def set_tenant
  #   if current_user.present? && current_user.account.present?
  #     set_current_tenant(current_user.account)
  #   else
  #     Rails.logger.debug "No tenant or current_user found"
  #     # Optionally, handle cases where no tenant is set
  #     raise ActsAsTenant::Errors::NoTenantSet
  #   end
  # end


  


  # GET /support_tickets or /support_tickets.json
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



  # POST /support_tickets or /support_tickets.json
#   def create
#     @support_ticket = SupportTicket.new(support_ticket_params)
   
#     if @support_ticket.valid?
#       prefix = ActsAsTenant.current_tenant&.ticket_setting.prefix
#       minimum_digits = ActsAsTenant.current_tenant&.ticket_setting.minimum_digits
      


#        unless prefix.present? && minimum_digits.present?
#       return render json: { error: "Please create a ticket number for the account" }, status: :unprocessable_entity
#     end

#       # if prefix.blank? && minimum_digits.blank?
#       # render json: { error: "Please create a ticket number for the account" }
        
#       # end
   

#       # return render json: { error: "Please create a ticket number for the account" } unless prefix.blank? && minimum_digits.blank?
        
#         @support_ticket.save!
#         Rails.logger.info "support ticket info after save: #{@support_ticket.inspect}"
#         ActivtyLog.create(action: 'create', ip: request.remote_ip,
#  description: "Created support ticket #{@support_ticket.ticket_number}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)
#         auto_generated_number = "#{prefix}#{@support_ticket.sequence_number.to_s.rjust(minimum_digits.to_i, '0')}"
#         @support_ticket.update!(
#           ticket_number: auto_generated_number,
#           date_of_creation: Time.now.strftime('%Y-%m-%d %I:%M:%S %p')
#         )
        
# # ticket_created_at = @support_ticket.date_of_creation.strftime('%Y-%m-%d %I:%M:%S %p')
# # customer_portal = request.headers['X-Original-Host']

# # company_name = ActsAsTenant.current_tenant.company_setting.company_name 
# # customer_support_email = ActsAsTenant.current_tenant.company_setting.customer_support_email 


# # service_provider,
# #     ticket_number, ticket_created_at, 
# #     customer_email, issue_description, ticket_status, ticket_priority,
# #     customer_code, customer_portal_link, company_name,
# #     customer_support_email

# # ServiceProviderTicketMailer.send_ticket_email(@support_ticket.agent ,@support_ticket.ticket_number,
# # ticket_created_at,customer_email, @support_ticket.issue_description, @support_ticket.status,
# # @support_ticket.priority, customers_code, customer_portal, company_name, customer_support_email,
# # service_provider_email).deliver_now

# #  SubscriberTicketMailer.send_ticket(@support_ticket.ticket_number,
# #  ticket_created_at,customer_email, @support_ticket.issue_description, @support_ticket.status,
# #  @support_ticket.priority, customers_code, customer_portal, company_name, customer_support_email).deliver_now



#         render json: @support_ticket, status: :created
      
#     else
#       render json: @support_ticket.errors, status: :unprocessable_entity 
#     end
    



#   end

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

  private
    # Use callbacks to share common setup or constraints between actions.
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




