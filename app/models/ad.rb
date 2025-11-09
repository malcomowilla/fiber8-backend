class Ad < ApplicationRecord
    acts_as_tenant(:account)

    validates :title, presence: true
    validates :description, presence: true
    validates :business_name, presence: true
    validates :business_type, presence: true

end
