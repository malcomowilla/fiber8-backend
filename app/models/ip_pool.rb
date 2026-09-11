require 'ipaddr'

class IpPool < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :nas_router
  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :ip_range_start, :ip_range_end, presence: true
  validate :ip_range_is_valid

  before_validation :normalize_status

  def total_ips
    IPAddr.new(ip_range_end).to_i - IPAddr.new(ip_range_start).to_i + 1
  rescue IPAddr::Error
    0
  end

  def available_ips
    [total_ips - used_ips, 0].max
  end

  def as_json(options = {})
    super(options).merge(
      'router_name'   => nas_router&.name,
      'total_ips'     => total_ips,
      'available_ips' => available_ips
    )
  end

  private

  def normalize_status
    self.status ||= 'active'
  end

  def ip_range_is_valid
    start_ip = IPAddr.new(ip_range_start)
    end_ip   = IPAddr.new(ip_range_end)

    errors.add(:ip_range_end, 'must be after range start') if end_ip.to_i < start_ip.to_i
  rescue IPAddr::Error, ArgumentError
    errors.add(:base, 'IP range start/end must be valid IPv4 addresses')
  end
end







# {{baseUrl}}/ppp/profile/add



# {
#   "address-list": "any",
#   "bridge": "any",
#   "bridge-horizon": "any",
#   "bridge-learning": "any",
#   "bridge-path-cost": "any",
#   "bridge-port-priority": "any",
#   "change-tcp-mss": "any",
#   "comment": "any",
#   "copy-from": "any",
#   "dhcpv6-pd-pool": "any",
#   "dns-server": "any",
#   "idle-timeout": "any",
#   "incoming-filter": "any",
#   "insert-queue-before": "any",
#   "interface-list": "any",
#   "local-address": "any",
#   "name": "any",
#   "on-down": "any",
#   "on-up": "any",
#   "only-one": "any",
#   "outgoing-filter": "any",
#   "parent-queue": "any",
#   "queue-type": "any",
#   "rate-limit": "any",
#   "remote-address": "any",
#   "remote-ipv6-prefix-pool": "any",
#   "session-timeout": "any",
#   "use-compression": "any",
#   "use-encryption": "any",
#   "use-ipv6": "any",
#   "use-mpls": "any",
#   "use-upnp": "any",
#   "wins-server": "any",
#   ".proplist": "any",
#   ".query": "array"
# }