namespace :wireguard do
  desc "Re-apply all WireGuard peer routes from the database"
  task reconcile_routes: :environment do
    require "ipaddr"

    # private_ip holds the LAN network(s) reachable through each peer —
    # that's what needs a Linux route. The peer's own tunnel address
    # (allowed_ips, e.g. 10.2.0.154/32) is already on-link via wg0's
    # own subnet route and needs no separate route.
    networks = ActsAsTenant.without_tenant do
      WireguardPeer.pluck(:private_ip)
    end.compact.reject(&:blank?).flat_map { |s| s.split(",") }.map(&:strip).uniq

    networks.each do |network|
      begin
        IPAddr.new(network) # sanity check before shelling out
        cmd = ["sudo", "/usr/local/sbin/wireguard-route", "add", network]
        success = system(*cmd)
        puts "#{success ? 'OK' : 'FAIL'}: #{cmd.join(' ')}"
      rescue IPAddr::InvalidAddressError => e
        warn "Skipping invalid network #{network}: #{e.message}"
      end
    end
  end
end