class WireguardPeerSerializer < ActiveModel::Serializer
  attributes :id, :public_key, :allowed_ips, :persistent_keepalive
end
