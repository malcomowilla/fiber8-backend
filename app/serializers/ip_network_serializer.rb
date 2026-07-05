# class IpNetworkSerializer < ActiveModel::Serializer
#   attributes :id, :network, :title, :ip_adress, :subnet_mask, :net_mask,
#   :client_host_range, :total_ip_addresses, :account_id, :nas





# end
# app/serializers/ip_network_serializer.rb
# require 'ipaddress'

class IpNetworkSerializer < ActiveModel::Serializer
  attributes :id, :network, :title, :ip_adress, :subnet_mask,
             :net_mask, :client_host_range, :total_ip_addresses,
             :account_id, :nas

  

  

             
  def net_mask
    # Calculate the actual netmask (e.g., 255.255.255.0)
    subnet = object.subnet_mask.to_i
    IPAddr.new('255.255.255.255').mask(subnet).to_s
  rescue
    nil
  end

  # def client_host_range
  #   network = IPAddr.new("#{object.network}/#{object.subnet_mask}").to_range
  #   fist_ip = network.first.to_s
  #   last_ip = network.last.to_s
  #   "#{fist_ip} - #{last_ip}"
  # end


#   def client_host_range
#  result = `ipcalc #{object.network}/#{object.subnet_mask}`
#   host_min = result[/HostMin:\s+(\S+)/, 1]
#   host_max = result[/HostMax:\s+(\S+)/, 1]
#   "#{host_min} - #{host_max}" if host_min && host_max    
    
#   end


  
  def client_host_range
  network = IPAddress("#{object.network}/#{object.subnet_mask}")

  return nil unless network.ipv4?

  first = network.first.to_s
  last  = network.last.to_s

  "#{first} - #{last}"
rescue StandardError
  nil
end


def total_ip_addresses
  network = IPAddress("#{object.network}/#{object.subnet_mask}")

  return 1 if network.prefix == 32
  return 2 if network.prefix == 31

  network.size - 2
rescue StandardError
  nil
end

  # def total_ip_addresses
  #   range = IPAddr.new("#{object.network}/#{object.subnet_mask}").to_range
  #   [range.count - 2, 0].max  # Prevents negative value for /31 or /32
  # end

  private

  def parsed_network
    @parsed_network ||= IPAddress(object.network) rescue nil
  end
end
