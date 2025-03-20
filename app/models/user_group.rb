class UserGroup < ApplicationRecord
  acts_as_tenant(:account)

end
