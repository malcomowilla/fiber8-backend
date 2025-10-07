

class CompanyIdJob 
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        
 Rails.logger.info "Processing company id...... => #{tenant.subdomain}"
         CompanyId.where(company_id: nil).find_each do |company|
          company.update!(company_id: generate_company_id,
          
          account_id: tenant.id
          )
        end

         Rails.logger.info "Processing company id...... after => #{tenant.subdomain}"


      end
      end
  end



  def generate_company_id
    "CID#{rand(100..999)}"
  end

end