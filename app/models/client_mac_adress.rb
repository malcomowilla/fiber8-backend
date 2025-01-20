class ClientMacAdress < ApplicationRecord

  acts_as_tenant(:account)
end



