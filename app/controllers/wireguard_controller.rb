# class WireguardController < ApplicationController
#   require 'securerandom'
#   require 'open3'


#   WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"  # WireGuard configuration path
#  Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#   def generate_config
#     # Generate WireGuard private key for the client
#     client_private_key, _stderr, _status = Open3.capture3("wg genkey")
#     client_private_key.strip!

#     # Generate WireGuard public key for the client
#     client_public_key, _stderr, _status = Open3.capture3("echo #{client_private_key} | wg pubkey")
#     client_public_key.strip!

#     # Retrieve server's public key from Ubuntu VPS
#     server_public_key, _stderr, _status = Open3.capture3("wg show wg0 public-key")
#     server_public_key.strip!

#     # Assign a random IP in 10.2.0.x range
#     client_ip = "10.2.0.#{rand(2..254)}/32"


    
#     # Generate MikroTik configuration for the client
#     mikrotik_config = <<~SCRIPT
#     /interface wireguard add name=wireguard1 private-key="#{client_private_key}"

#       /interface wireguard peers
#   add allowed-address=0.0.0.0/0 endpoint-address=102.221.35.92 endpoint-port=51820 interface=wireguard1 persistent-keepalive=25s public-key="#{server_public_key}"

#       /ip address
#       add address=#{client_ip} interface=wireguard1
#     SCRIPT

#     # Append new peer to wg0.conf (Ubuntu WireGuard server)
#     peer_config = <<~PEER

#       [Peer]
#       PublicKey = #{client_public_key}
#       AllowedIPs = #{client_ip}
#     PEER

#     File.open(WG_CONFIG_PATH, "a") do |file|
#       file.puts peer_config
#     end

#     # Apply the new configuration to WireGuard
#     system("wg set wg0 peer #{client_public_key} allowed-ips #{client_ip}")

#     # Restart WireGuard to apply new settings (if necessary)
#     system("systemctl restart wg-quick@wg0")

#     # Return MikroTik configuration as plain text
#     render plain: mikrotik_config
#   end

# end
# end
# end

  # Optional: Add route if needed
      # /ip route add dst-address=0.0.0.0/0 gateway=wireguard1

# class WireguardController < ApplicationController
#   require 'securerandom'
#   require 'open3'
#   require 'ipaddr'

#   WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"

#   def generate_config
#     # Get parameters from frontend
#     network_address = params[:network_address] || "10.2.0.0"
#     subnet_mask = params[:subnet_mask] || "24"
#     client_ip = params[:client_ip] # Optional: if user wants to specify exact IP

#     # Validate network address
#     begin
#       network = IPAddr.new("#{network_address}/#{subnet_mask}")
#     rescue IPAddr::InvalidAddressError => e
#       render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
#       return
#     end

#     # Generate keys
#     client_private_key, _ = Open3.capture3("wg genkey")
#     client_private_key.strip!
#     client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
#     client_public_key.strip!
#     server_public_key, _ = Open3.capture3("wg show wg0 public-key")
#     server_public_key.strip!

#     # Assign IP address
#     assigned_ip = if client_ip.present?
#       begin
#         client_ip_obj = IPAddr.new(client_ip)
#         unless network.include?(client_ip_obj)
#           render json: { error: "Specified IP #{client_ip} is not in network #{network_address}/#{subnet_mask}" }, 
#                  status: :bad_request
#           return
#         end
#         "#{client_ip}/#{subnet_mask}"
#       rescue IPAddr::InvalidAddressError => e
#         render json: { error: "Invalid client IP: #{e.message}" }, status: :bad_request
#         return
#       end
#     else
#       host_range = network.to_range
#       random_ip = host_range.to_a[1..-2].sample || host_range.first.succ
#       "#{random_ip}/#{subnet_mask}"
#     end

#     # Generate configurations
#     mikrotik_config = generate_mikrotik_config(client_private_key, server_public_key, assigned_ip)
#     server_config = generate_server_config(client_public_key, assigned_ip)

#     # Save to server configuration
#     begin
#       File.open(WG_CONFIG_PATH, "a") { |file| file.puts(server_config) }
#       system("wg set wg0 peer #{client_public_key} allowed-ips #{assigned_ip}")
#       system("systemctl restart wg-quick@wg0") if Rails.env.production?
#     rescue => e
#       render json: { error: "Failed to update WireGuard configuration: #{e.message}" }, 
#              status: :internal_server_error
#       return
#     end

#     render json: { 
#       mikrotik_config: mikrotik_config,
#       server_config: server_config,
#       client_ip: assigned_ip,
#       network: "#{network_address}/#{subnet_mask}",
#       private_key: client_private_key,
#       public_key: client_public_key
#     }
#   end

#   private

#   def generate_mikrotik_config(private_key, server_pubkey, ip)
#     <<~CONFIG
#       # WireGuard MikroTik Configuration
#       /interface wireguard add name=wireguard1 private-key="#{private_key}"
      
 
#       /interface wireguard peers add \\
#         allowed-address=0.0.0.0/0 \\
#         endpoint-address=102.221.35.92
#         endpoint-port=51820 \\
#         interface=wireguard1 \\
#         persistent-keepalive=25s \\
#         public-key="#{server_pubkey}"
      
#       /ip address add address=#{ip} interface=wireguard1
      
    
#     CONFIG
#   end

#   def generate_server_config(client_pubkey, ip)
#     <<~CONFIG
#       # Add this to your WireGuard server config (/etc/wireguard/wg0.conf)
#       [Peer]
#       PublicKey = #{client_pubkey}
#       AllowedIPs = #{ip}
#       # PersistentKeepalive = 25 (uncomment if client is behind NAT)
#     CONFIG
#   end
# end
# 
class WireguardController < ApplicationController
  require 'securerandom'
  require 'open3'
  require 'ipaddr'

  WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"

  def generate_config
    # Get parameters from frontend
    network_address = params[:network_address] || "10.2.0.0"
    subnet_mask = params[:subnet_mask] || "24"
    client_ip = params[:client_ip] # Optional: if user wants to specify exact IP
  
    # Validate network address
    begin
      network = IPAddr.new("#{network_address}/#{subnet_mask}")
    rescue IPAddr::InvalidAddressError => e
      render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
      return
    end
  
    # Generate keys
    client_private_key, _ = Open3.capture3("wg genkey")
    client_private_key.strip!
    client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
    client_public_key.strip!
    server_public_key, _ = Open3.capture3("wg show wg0 public-key")
    server_public_key.strip!
  
    # Assign IP address
    assigned_ip = if client_ip.present?
      begin
        client_ip_obj = IPAddr.new(client_ip)
        unless network.include?(client_ip_obj)
          render json: { error: "Specified IP #{client_ip} is not in network #{network_address}/#{subnet_mask}" }, 
                 status: :bad_request
          return
        end
        "#{client_ip}/#{subnet_mask}"
      rescue IPAddr::InvalidAddressError => e
        render json: { error: "Invalid client IP: #{e.message}" }, status: :bad_request
        return
      end
    else
      host_range = network.to_range
      random_ip = host_range.to_a[1..-2].sample || host_range.first.succ
      "#{random_ip}/#{subnet_mask}"
    end
  
    # Calculate server's dynamic address (first IP in the range)
    # server_ip = network.to_range.first.to_s
    ip_range = network.to_range
    server_ip = ip_range.first.succ.to_s
  
    # Generate configurations
    mikrotik_config = generate_mikrotik_config(client_private_key, server_public_key, assigned_ip)
    server_config = generate_server_config(client_public_key, assigned_ip)
  
    # Save to WireGuard server configuration
    begin
      # Open the configuration file to modify it
      config_lines = File.readlines(WG_CONFIG_PATH)
  
      # Check if the [Interface] section exists
      interface_section_index = config_lines.index { |line| line.strip == '[Interface]' }
      
      if interface_section_index
        # If [Interface] exists, update the Address line (find and replace it)
        updated = false
        config_lines.each_with_index do |line, index|
          if line.strip.start_with?('Address') # Update Address line in the [Interface] section
            config_lines[index] = "Address = #{server_ip}/#{subnet_mask}\n"
            updated = true
          end
        end
  
        # If no Address line was updated, add it to the [Interface] section
        unless updated
          config_lines.insert(interface_section_index + 1, "Address = 10.2.0.2/#{subnet_mask}\n")
        end
      else
        # If [Interface] doesn't exist, append it to the end of the config
        config_lines << "\n[Interface]\nAddress = #{server_ip}/#{subnet_mask}\n"
      end
  
      # Append the client peer config to the file
      config_lines << "\n# Added by WireGuardController for peer #{client_public_key}\n"
      config_lines << server_config
  
      # Write the modified config back to the file
      File.open(WG_CONFIG_PATH, 'w') { |file| file.puts(config_lines) }
  
      # Apply the configuration and restart WireGuard service
      system("wg set wg0 peer #{client_public_key} allowed-ips #{assigned_ip}")
      system("systemctl restart wg-quick@wg0") if Rails.env.production?
    rescue => e
      render json: { error: "Failed to update WireGuard configuration: #{e.message}" }, 
             status: :internal_server_error
      return
    end
  
    render json: { 
      mikrotik_config: mikrotik_config,
      server_config: server_config,
      client_ip: assigned_ip,
      network: "#{network_address}/#{subnet_mask}",
      private_key: client_private_key,
      public_key: client_public_key
    }
  end
  
  private

  def generate_mikrotik_config(private_key, server_pubkey, ip)
    <<~CONFIG
      # WireGuard MikroTik Configuration
      /interface wireguard add name=wireguard1 private-key="#{private_key}"
      
 
      /interface wireguard peers add \\
        allowed-address=0.0.0.0/0 \\
        endpoint-address=102.221.35.92
        endpoint-port=51820 \\
        interface=wireguard1 \\
        persistent-keepalive=25s \\
        public-key="#{server_pubkey}"
      
      /ip address add address=#{ip} interface=wireguard1
      
    
    CONFIG
  end

  def generate_server_config(client_pubkey, ip)
    <<~CONFIG
      # Add this to your WireGuard server config (/etc/wireguard/wg0.conf)
      [Peer]
      PublicKey = #{client_pubkey}
      AllowedIPs = #{ip}
      # PersistentKeepalive = 25 (uncomment if client is behind NAT)
    CONFIG
  end
end



