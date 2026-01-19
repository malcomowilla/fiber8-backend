class TemporarySession < ApplicationRecord
   acts_as_tenant(:account)

end
