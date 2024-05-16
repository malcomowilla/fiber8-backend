class Account < ApplicationRecord
    has_many :users
    has_many :packages
    has_many :nas_routers
    has_many :zones
    
end
