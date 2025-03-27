


class RadCheck < ApplicationRecord
  self.table_name = 'radcheck'  # Explicitly set the table name
  acts_as_tenant(:account)
end


