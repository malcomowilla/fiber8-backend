class NasRouter < ApplicationRecord
    acts_as_tenant(:account)

end


