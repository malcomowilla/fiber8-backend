class OnuSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :oui, :product_class, :manufacturer, :onu_id, :status, 
  :last_inform, :account_id, :last_boot, :ssid1, :ssid2, :software_version, :hardware_version,
  :uptime, :ram_used, :cpu_used, :dhcp_uptime, :dhcp_name, :dhcp_addressing_type,
   :dhcp_connection_status, :dhcp_ip, :dhcp_subnet_mask, :dhcp_gateway, 
   :dhcp_dns_servers, :dhcp_last_connection_error, :dhcp_mac_address, 
   :dhcp_max_mtu_size, :dhcp_nat_enabled, :dhcp_vlan_id,


def status
  return "offline" unless object.last_inform.present?

  last_inform_time = Time.parse(object.last_inform).in_time_zone("Africa/Nairobi") 
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


