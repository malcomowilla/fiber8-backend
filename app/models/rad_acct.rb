class RadAcct < ApplicationRecord
  self.table_name = 'radacct'  # Explicitly set the table name
  acts_as_tenant(:account)
  
end









