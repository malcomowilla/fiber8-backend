class WireguardPeer < ApplicationRecord
      acts_as_tenant(:account)

end
