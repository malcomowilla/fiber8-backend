class Cdr < ApplicationRecord
  self.table_name = "cdr"
  self.primary_key = "uniqueid"
    acts_as_tenant(:account)

end




