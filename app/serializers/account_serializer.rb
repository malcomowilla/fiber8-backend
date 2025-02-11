class AccountSerializer < ActiveModel::Serializer
  attributes :id, :subdomain
  has_many :users
end
