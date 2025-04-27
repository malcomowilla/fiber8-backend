class RadAcct < ApplicationRecord
  self.table_name = 'radacct'
  acts_as_tenant(:account)

  self.ignored_columns = ["class"]

  # Set the account_id for records without it
  # def self.set_account_id_for_missing_account
  #   RadAcct.where(account_id: nil).find_each do |radacct|
  #     radacct.update(account_id: ActsAsTenant.current_tenant.id)
  #   end
  # end
end









