class GenerateInvoiceJob
  include Sidekiq::Job

  def perform(_invoice_id = nil)
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        # Process hotspot plan
        if tenant.hotspot_plan.present? && tenant.hotspot_plan.expiry_days.present?
          process_plan_invoice(tenant, tenant.hotspot_plan.name, tenant.hotspot_plan.price)
        end

        # Process PPPoE plan
        if tenant.pp_poe_plan.present? && tenant.pp_poe_plan.expiry_days.present?
          process_plan_invoice(tenant, tenant.pp_poe_plan.name, tenant.pp_poe_plan.price)
        end
      end
    end
  end

  private

  def process_plan_invoice(tenant, plan_name, plan_amount)
    expiry_date = plan.created_at + plan.expiry_days.days
    invoice_date = expiry_date - 29.days

    if Date.current == invoice_date.to_date
      Invoice.create!(
        invoice_number: generate_invoice_number,
        invoice_date: Date.current,
        due_date: expiry_date,
        invoice_desciption: plan_name,
        total: plan_amount,
        status: "unpaid",
        account_id: tenant.id
      )
    end
  end

  def generate_invoice_number
    "INV#{Time.current.strftime("%Y%m%d%H%M%S")}#{rand(100..999)}"
  end
end
