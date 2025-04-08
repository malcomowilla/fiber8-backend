class IpNetworkSerializer < ActiveModel::Serializer
  attributes :id, :network, :title, :ip_adress, :account_id
end
