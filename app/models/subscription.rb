class Subscription < ApplicationRecord
    acts_as_tenant(:account)
    belongs_to :subscriber
    # validates :ppoe_username, presence: true
    # validates :ppoe_password, presence: true

    # validates :ppoe_username, uniqueness: true

end
