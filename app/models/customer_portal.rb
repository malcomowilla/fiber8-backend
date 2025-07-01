class CustomerPortal < ApplicationRecord
      has_secure_password
      acts_as_tenant(:account)
end
