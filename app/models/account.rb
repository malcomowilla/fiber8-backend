class Account < ApplicationRecord
    has_many :users
    has_many :packages
    has_many :nas_routers
    has_many :zones
    has_many :subscribers
    has_many :subscriptions
    has_many :prefix_and_digits
    has_one :company_setting
    
end
