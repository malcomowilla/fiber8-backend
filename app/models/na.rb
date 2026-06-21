class Na < ApplicationRecord
  self.inheritance_column = nil  
  acts_as_tenant(:account)

#   after_commit :regenerate_clients_conf

# def regenerate_clients_conf
#   GenerateClientsConfJob.perform_async
# end

end
