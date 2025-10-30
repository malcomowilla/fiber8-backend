class GenerateInvoiceJob
   include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        # Rails.logger.info "Processing plan invoice for => #{tenant.subdomain}"

                  
          Rails.logger.info "Processing hotspot and ppoe plan invoice for => #{tenant.subdomain}"

        if tenant.hotspot_plan.present? && tenant.hotspot_plan&.name.present? && tenant.hotspot_plan.name != 'Free Trial'
        if tenant.hotspot_plan.present? && tenant.hotspot_plan&.expiry.present? && tenant.hotspot_plan&.expiry + tenant.hotspot_plan.expiry_days.days < Time.current



     if !tenant.invoices.where(plan_name: tenant.hotspot_plan.name).present? 
          tenant.hotspot_plan.update!(last_invoiced_at: Time.current)
          process_hotspot_plan_invoice(tenant, tenant.hotspot_plan.name, tenant.hotspot_plan.price, 
          tenant.hotspot_plan.expiry_days, tenant.hotspot_plan.expiry)
           end
        end
      
        end
        


        # Process PPPoE plan
         if tenant.pp_poe_plan.present? && tenant.pp_poe_plan&.name.present? && tenant.pp_poe_plan.name != 'Free Trial'
         if tenant.pp_poe_plan.present? && tenant.pp_poe_plan.expiry.present? && tenant.pp_poe_plan.expiry + tenant.pp_poe_plan.expiry_days.days < Time.current

                     if !tenant.invoices.where(plan_name: tenant.pp_poe_plan.name).present?
                      tenant.pp_poe_plan.update!(last_invoiced_at: Time.current)
          process_pppoe_plan_invoice(tenant, tenant.pp_poe_plan.name, tenant.pp_poe_plan.price, 
          tenant.pp_poe_plan.expiry_days, tenant.pp_poe_plan.expiry)
        end
        end
      end
    



      end


    end



  end

  private





def process_hotspot_plan_invoice(tenant, plan_name, plan_amount, expiry_days, expiry)
    
Rails.logger.info "Processing hotspot plan invoice for => #{tenant.subdomain}"
      Invoice.create!(
        invoice_number: generate_invoice_number,
        plan_name: plan_name,
         invoice_date: Time.current,
        due_date: expiry + expiry_days.days,
        invoice_desciption: "payment for hotspot license => #{plan_name}",
        total: plan_amount,
        status: "unpaid",
        account_id: tenant.id,
        last_invoiced_at: Time.current,

      )
    
end






  def process_pppoe_plan_invoice(tenant, plan_name, plan_amount, expiry_days, expiry)
    Rails.logger.info "Processing PPPoE plan invoice for => #{tenant.subdomain}"

      Invoice.create!(
        invoice_number: generate_invoice_number,
        plan_name: plan_name,
        invoice_date: Time.current,
        due_date: expiry + expiry_days.days,
        invoice_desciption: "payment for pppoe license => #{plan_name}",
        total: plan_amount,
        status: "unpaid",
        account_id: tenant.id,
        last_invoiced_at: Time.current,

      )
    
  end




  def generate_invoice_number
    "INV#{Time.current.strftime("%Y%m%d%H%M%S")}#{rand(100..999)}"
  end





  


  
end
