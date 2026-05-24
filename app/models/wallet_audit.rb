class WalletAudit < ApplicationRecord
  acts_as_tenant(:account)
end
