class Na < ApplicationRecord

  acts_as_tenant(:account)

end
