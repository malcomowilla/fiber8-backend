class OnuSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :oui, :product_class, :manufacturer, :onu_id, :status, 
  :last_inform, :account_id, :last_boot, :ssid1, :ssid2, :software_version, :hardware_version,
  :uptime, :ram_used, :cpu_used, :dhcp_uptime, :dhcp_name, :dhcp_addressing_type,
   :dhcp_connection_status, :dhcp_ip, :dhcp_subnet_mask, :dhcp_gateway, 
   :dhcp_dns_servers, :dhcp_last_connection_error, :dhcp_mac_address, 
   :dhcp_max_mtu_size, :dhcp_nat_enabled, :dhcp_vlan_id, :wifi_password1, :wifi_password2,
   :wlan1_status, :enable1, :rf_band1, :radio_enabled1, :total_associations1, :ssid_advertisment_enabled1,
   :wpa_encryption1, :channel_width1, :autochannel1, :channel, :country_regulatory_domain1,:tx_power1,
   :authentication_mode1, :standard1, :lan_ip_interface_address, :lan_ip_interface_net_mask, :dhcp_server_enable,
   :dhcp_ip_pool_min_addr, :dhcp_ip_pool_max_addr, :dhcp_server_subnet_mask, :dhcp_server_default_gateway, 
   :dhcp_server_dns_servers, :lease_time, :clients_domain_name, :reserved_ip_address




def status
  return "offline" unless object.last_inform.present?
  last_inform_time = Time.parse(object.last_inform).in_time_zone(GeneralSetting.first&.timezone || "Africa/Nairobi") 
  if last_inform_time > 5.minutes.ago
    "active"
  else
    "offline"
  end
end








 def cpu_used
    return unless object.cpu_used.present?
    "#{object.cpu_used}%"
  end


def ram_used
    return unless object.ram_used.present?
    "#{object.ram_used}%"
  end



 def uptime
    return unless object.uptime.present?

    seconds = object.uptime.to_i

    mm, ss = seconds.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)

    parts = []
    parts << "#{dd}d" if dd > 0
    parts << "#{hh}h" if hh > 0
    parts << "#{mm}m" if mm > 0
    parts << "#{ss}s" if ss > 0
    parts.join(" ")
  end



def lease_time
  return unless object.lease_time.present?

    seconds = object.lease_time.to_i

    mm, ss = seconds.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)

    parts = []
    parts << "#{dd}d" if dd > 0
    parts << "#{hh}h" if hh > 0
    parts << "#{mm}m" if mm > 0
    parts << "#{ss}s" if ss > 0
    parts.join(" ")
  
end


  def dhcp_uptime
    return unless object.dhcp_uptime.present?

    seconds = object.dhcp_uptime.to_i

    mm, ss = seconds.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)

    parts = []
    parts << "#{dd}d" if dd > 0
    parts << "#{hh}h" if hh > 0
    parts << "#{mm}m" if mm > 0
    parts << "#{ss}s" if ss > 0
    parts.join(" ")
  end

 def last_inform
  return unless object.last_inform.present?
  Time.parse(object.last_inform).strftime("%B %d, %Y at %I:%M %p")
end




end


