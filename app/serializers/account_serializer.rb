class AccountSerializer < ActiveModel::Serializer
  attributes :id, :name, :subdomain
end
