json.extract! wireguard_peer, :id, :public_key, :allowed_ips, :persistent_keepalive, :created_at, :updated_at
json.url wireguard_peer_url(wireguard_peer, format: :json)
