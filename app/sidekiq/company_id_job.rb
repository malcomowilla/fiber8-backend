class CompanyIdJob
  include Sidekiq::Job
  queue_as :default
sidekiq_options lock: :until_executed, lock_timeout: 0


  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        Rails.logger.info "Processing company ID for tenant => #{tenant.subdomain}"

        # find or create a company_id record for this account
        company_id_record = CompanyId.find_or_initialize_by(account_id: tenant.id)

        if company_id_record.company_id.blank?
          company_id_record.company_id = generate_company_id
          company_id_record.save!
          Rails.logger.info "Generated company ID #{company_id_record.company_id} for #{tenant.subdomain}"
        else
          Rails.logger.info "Company ID already exists for #{tenant.subdomain}"
        end
      end
    end
  end

  private

  def generate_company_id
    "CID#{rand(100..999)}"
  end
end
