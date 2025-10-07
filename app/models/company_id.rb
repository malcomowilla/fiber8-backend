class CompanyId < ApplicationRecord
   acts_as_tenant(:account)
end
