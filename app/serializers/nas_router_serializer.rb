class NasRouterSerializer < ActiveModel::Serializer
  attributes :id, :name, :ip_address, :username, :password
end
