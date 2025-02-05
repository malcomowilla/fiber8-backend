class Sm < ApplicationRecord
  acts_as_tenant(:account)

end
