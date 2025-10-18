class GenerateInvoiceJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        Rails.logger.info "Processing plan invoice for => #{tenant.subdomain}"

        # ✅ Process Hotspot Plan
        hotspot_plan = tenant.hotspot_plan
        if hotspot_plan.present? && hotspot_plan.name != 'Free Trial'
          if hotspot_plan.expiry.present? && hotspot_plan.expiry > Time.current
            if hotspot_plan.last_invoiced_at.nil?
              hotspot_plan.update!(last_invoiced_at: Time.current)
              process_hotspot_plan_invoice(
                tenant,
                hotspot_plan.name,
                hotspot_plan.price,
                hotspot_plan.expiry_days
              )
            end
          end
        end

        # ✅ Process PPPoE Plan
        pppoe_plan = tenant.pp_poe_plan
        if pppoe_plan.present? && pppoe_plan.name != 'Free Trial'
          if pppoe_plan.expiry.present? && pppoe_plan.expiry > Time.current
            if pppoe_plan.last_invoiced_at.nil?
              pppoe_plan.update!(last_invoiced_at: Time.current)
              process_pppoe_plan_invoice(
                tenant,
                pppoe_plan.name,
                pppoe_plan.price,
                pppoe_plan.expiry_days
              )
            end
          end
        end
      end
    end
  end

  private

  def process_hotspot_plan_invoice(tenant, plan_name, plan_amount, expiry_days)
    Rails.logger.info "Processing hotspot plan invoice for => #{tenant.subdomain}"
    Invoice.create!(
      invoice_number: generate_invoice_number,
      invoice_date: Time.current,
      due_date: Time.current + expiry_days.days,
      invoice_desciption: "Payment for hotspot license => #{plan_name}",
      total: plan_amount,
      status: "unpaid",
      account_id: tenant.id
    )
  end

  def process_pppoe_plan_invoice(tenant, plan_name, plan_amount, expiry_days)
    Rails.logger.info "Processing PPPoE plan invoice for => #{tenant.subdomain}"
    Invoice.create!(
      invoice_number: generate_invoice_number,
      invoice_date: Time.current,
      due_date: Time.current + expiry_days.days,
      invoice_desciption: "Payment for PPPoE license => #{plan_name}",
      total: plan_amount,
      status: "unpaid",
      account_id: tenant.id
    )
  end

  def generate_invoice_number
    "INV#{Time.current.strftime("%Y%m%d%H%M%S")}#{rand(100..999)}"
  end
end
