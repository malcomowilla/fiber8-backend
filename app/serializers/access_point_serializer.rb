class AccessPointSerializer < ActiveModel::Serializer
  attributes :id, :name, :ping, :status, :checked_at, :account_id, :ip, :response, :reachable
end
