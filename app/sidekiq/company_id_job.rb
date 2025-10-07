

class CompanyIdJob 
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        

         Company.where(company_id_id: nil).find_each do |company|
          company.update!(company_id: generate_company_id)
        end


      end
      end
  end



  def generate_company_id
    "CID#{rand(100..999)}"
  end

end