class Account < ApplicationRecord
    has_many :users
    has_many :p_poe_packages
end
