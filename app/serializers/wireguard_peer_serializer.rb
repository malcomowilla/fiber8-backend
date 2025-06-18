class WireguardPeerSerializer < ActiveModel::Serializer
  attributes :id, :allowed_ips, :persistent_keepalive,
             :private_ip
end
