class Invoice < ApplicationRecord
    acts_as_tenant(:account)

end
