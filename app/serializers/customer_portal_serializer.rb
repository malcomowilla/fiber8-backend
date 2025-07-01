class CustomerPortalSerializer < ActiveModel::Serializer
  attributes :id, :username, :password, :account_id
end
