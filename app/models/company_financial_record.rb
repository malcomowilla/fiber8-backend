class CompanyFinancialRecord < ApplicationRecord
  acts_as_tenant(:account)
end
