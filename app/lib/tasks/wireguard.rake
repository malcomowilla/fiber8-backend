namespace :wireguard do
  desc "Re-apply all WireGuard peer routes from the database"
  task reconcile_routes: :environment do
    require "ipaddr"

    networks = ActsAsTenant.without_tenant do
      WireguardPeer.pluck(:allowed_ips)
    end.compact.flat_map { |s| s.split(",") }.map(&:strip).uniq

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