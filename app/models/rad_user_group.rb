

class RadUserGroup < ApplicationRecord
acts_as_tenant(:account)
  self.table_name = 'radusergroup'  # Explicitly set the table name
end



