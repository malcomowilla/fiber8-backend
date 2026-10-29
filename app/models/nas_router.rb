class NasRouter < ApplicationRecord
    acts_as_tenant(:account)
has_many :router_status_logs, dependent: :delete_all
end




