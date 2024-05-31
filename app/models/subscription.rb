class Subscription < ApplicationRecord
    acts_as_tenant(:account)

end
