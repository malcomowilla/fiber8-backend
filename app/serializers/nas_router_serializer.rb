class NasRouterSerializer < ActiveModel::Serializer
  attributes :id, :name, :ip_address, :username, :account_id

  # :password
end
