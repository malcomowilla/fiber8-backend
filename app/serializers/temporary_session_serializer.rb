class TemporarySessionSerializer < ActiveModel::Serializer
  attributes :id, :session, :ip, :created_at, :account_id
end
