class WireguardController < ApplicationController
  require 'securerandom'
  require 'open3'

  WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"  # WireGuard configuration path

  def generate_config
    # Generate WireGuard private key for the client
    client_private_key, _stderr, _status = Open3.capture3("wg genkey")
    client_private_key.strip!

    # Generate WireGuard public key for the client
    client_public_key, _stderr, _status = Open3.capture3("echo #{client_private_key} | wg pubkey")
    client_public_key.strip!

    # Retrieve server's public key from Ubuntu VPS
    server_public_key, _stderr, _status = Open3.capture3("wg show wg0 public-key")
    server_public_key.strip!

    # Assign a random IP in 10.2.0.x range
    client_ip = "10.2.0.#{rand(2..254)}/32"


    
    # Generate MikroTik configuration for the client
    mikrotik_config = <<~SCRIPT
      /interface wireguard

      add listen-port=13231 mtu=1420 name=wireguard1 private-key="#{client_private_key}

      /interface wireguard peers
  add allowed-address=#{client_ip} endpoint-address=102.221.35.92 endpoint-port=51820 interface=wireguard1 persistent-keepalive=25s public-key="#{server_public_key}"

      /ip address
      add address=#{client_ip} interface=wireguard1
    SCRIPT

    # Append new peer to wg0.conf (Ubuntu WireGuard server)
    peer_config = <<~PEER

      [Peer]
      PublicKey = #{client_public_key}
      AllowedIPs = #{client_ip}
    PEER

    File.open(WG_CONFIG_PATH, "a") do |file|
      file.puts peer_config
    end

    # Apply the new configuration to WireGuard
    system("wg set wg0 peer #{client_public_key} allowed-ips #{client_ip}")

    # Restart WireGuard to apply new settings (if necessary)
    system("systemctl restart wg-quick@wg0")

    # Return MikroTik configuration as plain text
    render plain: mikrotik_config
  end
end
