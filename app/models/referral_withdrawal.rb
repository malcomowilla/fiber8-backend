
class ReferralWithdrawal < ApplicationRecord
  belongs_to :referrer, polymorphic: true
end