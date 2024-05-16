class Package < ApplicationRecord
    acts_as_tenant(:account)
    validates :name,  uniqueness: {case_sensitive: true}
    
end
