class PPoePackage < ApplicationRecord
# after_create_commit :broadcast_creation
# after_rollback :broadcast_creation_failure
    # after_commit :broadcast_packages
    # validates :name, uniqueness: true
    # validates :price, uniqueness: true
acts_as_tenant(:account)
private

# def broadcast_creation
#     ActionCable.server.broadcast("ppoe_packages_channel", message: 'Package Succesfully created', package: self.to_json)
    
# end




def broadcast_packages

# package_data = {
#     name: self.name
# }
#     packages = PPoePackage.all
#     puts packages
#     ActionCable.server.broadcast("ppoe_packages_channel", packages)
  end
# def broadcast_creation_failure
#   ActionCable.server.broadcast("ppoe_packages_channel", error: 'Package Creation Failed', package: self.to_json )
# end
end
