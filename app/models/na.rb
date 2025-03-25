class Na < ApplicationRecord
  self.inheritance_column = nil  # Disables STI
  acts_as_tenant(:account)

end
