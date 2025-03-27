


class RadCheck < ApplicationRecord
acts_as_tenant(:account)
  self.table_name = 'radcheck'  # Explicitly set the table name
end


