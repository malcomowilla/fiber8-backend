class Subscriber < ApplicationRecord
    acts_as_tenant(:account)
    auto_increment :sequence_number
        has_secure_password(validations: false)

      acts_as_tenant(:account)
# validates :phone_number, presence: true
# validates :name, uniqueness: true
# validates :ppoe_username, uniqueness: true




# validates :ppoe_username, presence: true
# validates :phone_number, uniqueness: true


end
