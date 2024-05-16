class Zone < ApplicationRecord
    acts_as_tenant(:account)

end
