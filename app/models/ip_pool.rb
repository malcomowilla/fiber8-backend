class IpPool < ApplicationRecord

  acts_as_tenant(:account)
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