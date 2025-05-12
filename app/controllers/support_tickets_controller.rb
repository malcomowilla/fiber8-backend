class SupportTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  load_and_authorize_resource


  def set_tenant
   
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
  
  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
  ActsAsTenant.current_tenant = @account
  set_current_tenant(@account)
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
    
  


def get_specific_ticket
  customer_code = Customer.find_by(customer_code: params[:my_customer_code])
end



  # POST /support_tickets or /support_tickets.json
  def create
    @support_ticket = SupportTicket.new(support_ticket_params)
    # customer_name = @support_ticket.customer
    # service_provider_name = @support_ticket.agent
    # service_provider_by_name = ServiceProvider.find_by(name: service_provider_name)
    # customer_by_name = Customer.find_by(name: customer_name)
    # service_provider_email = service_provider_by_name.email

    # customer_email = customer_by_name.email
    # customers_code = customer_by_name.customer_code

    if @support_ticket.valid?
      Rails.logger.info "current tenant in ticket settings =>#{ActsAsTenant.current_tenant.ticket_setting}"
      prefix = ActsAsTenant.current_tenant.ticket_setting.prefix
      minimum_digits = ActsAsTenant.current_tenant.ticket_setting.minimum_digits
      
   

      # return render json: { error: "Prefix and digit not found for the account" } unless prefix.blank? && minimum_digits.blank?
        
        @support_ticket.save!
        Rails.logger.info "support ticket info after save: #{@support_ticket.inspect}"
        
        auto_generated_number = "#{prefix}#{@support_ticket.sequence_number.to_s.rjust(minimum_digits.to_i, '0')}"
        @support_ticket.update!(
          ticket_number: auto_generated_number,
          date_of_creation: Time.now.strftime('%Y-%m-%d %I:%M:%S %p')
        )
        
# ticket_created_at = @support_ticket.date_of_creation.strftime('%Y-%m-%d %I:%M:%S %p')
# customer_portal = request.headers['X-Original-Host']

# company_name = ActsAsTenant.current_tenant.company_setting.company_name 
# customer_support_email = ActsAsTenant.current_tenant.company_setting.customer_support_email 


# service_provider,
#     ticket_number, ticket_created_at, 
#     customer_email, issue_description, ticket_status, ticket_priority,
#     customer_code, customer_portal_link, company_name,
#     customer_support_email

# ServiceProviderTicketMailer.send_ticket_email(@support_ticket.agent ,@support_ticket.ticket_number,
# ticket_created_at,customer_email, @support_ticket.issue_description, @support_ticket.status,
# @support_ticket.priority, customers_code, customer_portal, company_name, customer_support_email,
# service_provider_email).deliver_now

#  SubscriberTicketMailer.send_ticket(@support_ticket.ticket_number,
#  ticket_created_at,customer_email, @support_ticket.issue_description, @support_ticket.status,
#  @support_ticket.priority, customers_code, customer_portal, company_name, customer_support_email).deliver_now



        render json: @support_ticket, status: :created
      
    else
      render json: @support_ticket.errors, status: :unprocessable_entity 
    end
    



  end



  def update
    support_ticket = SupportTicket.find_by(id: params[:id])
      if support_ticket.update(support_ticket_params)
        support_ticket.update(date_closed: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
         render json: support_ticket, status: :ok
      else
         render json: support_ticket.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /support_tickets/1 or /support_tickets/1.json
  def destroy
    @support_ticket.destroy!

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




