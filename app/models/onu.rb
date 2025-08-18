class Onu < ApplicationRecord
      acts_as_tenant(:account)

end
