class TemporarySession < ApplicationRecord
   acts_as_tenant(:account)
   belongs_to :hotspot_voucher, optional: true
end
