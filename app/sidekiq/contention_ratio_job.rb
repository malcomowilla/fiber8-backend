# require 'net/http'
# require 'uri'
# require 'json'

# class ContentionRatioJob
#   include Sidekiq::Job
#   queue_as :default

#   def perform
#     NasRouter.all.each do |router|
#       begin
#         router_ip       = router.ip_address
#         router_username = router.username
#         router_password = router.password

#         # Step 1: Fetch active PPPoE users
#         active_users = fetch_active_users(router_ip, router_username, router_password)
#         next if active_users.blank?

#         active_users.each do |user|
#           pppoe_username = user['name']
#           subscription   = Subscription.find_by(ppoe_username: pppoe_username)
#           next unless subscription

#           package = Package.find_by(name: subscription.package_name)
#           next unless package&.aggregation.present?

#   same_package_users = active_users.count do |u|
#     sub = Subscription.find_by(ppoe_username: u['name'])
#     sub&.package_name == subscription.package_name
#   end

#   same_package_users = [same_package_users, 1].max


#           download_limit    = package.download_limit.to_f
#           upload_limit      = package.upload_limit.to_f

#           shared_download = (download_limit / same_package_users).round(2)
#   shared_upload   = (upload_limit / same_package_users).round(2)
#           queue_name = "queue_#{pppoe_username}_#{subscription.subscriber.name}"
#           target_ip  = subscription.ip_address
#           next if target_ip.blank?

#           # Step 2: Check if queue already exists
#           if queue_exists?(router_ip, router_username, router_password, queue_name)
#             Rails.logger.info "[ContentionRatioJob] Queue exists for #{queue_name}, skipping."
#             next
#           end

#           # Step 3: Add queue
#           payload = {
#             name: queue_name,
#             target: target_ip,
#             "max-limit": "#{shared_upload}M/#{shared_download}M",
#             "burst-threshold": "#{package.burst_threshold_upload}/#{package.burst_threshold_download}",
#             "burst-limit": "#{package.burst_upload_speed}M/#{package.burst_download_speed}M",
#             "burst-time": "#{package.burst_time}/#{package.burst_time}"
#           }

#           add_queue(router_ip, router_username, router_password, payload)
#           Rails.logger.info "[ContentionRatioJob] Queue added for #{queue_name}"
#         end
#       rescue => e
#         Rails.logger.info "[ContentionRatioJob] Error for router #{router.name}: #{e.message}"
#       end
#     end
#   end

#   private

#   def fetch_active_users(ip, username, password)
#     uri = URI("http://#{ip}/rest/ppp/active")
#     req = Net::HTTP::Get.new(uri)
#     req.basic_auth(username, password)

#     res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
#     return [] unless res.is_a?(Net::HTTPSuccess)

#     JSON.parse(res.body)
#   rescue => e
#     Rails.logger.info "Failed to fetch active users: #{e.message}"
#     []
#   end

#   def queue_exists?(ip, username, password, queue_name)
#     uri = URI("http://#{ip}/rest/queue/simple/find?name=#{queue_name}")
#     req = Net::HTTP::Get.new(uri)
#     req.basic_auth(username, password)

#     res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

#     res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body).any?
#   rescue => e
#     Rails.logger.info "Failed to check queue #{queue_name} existence: #{e.message}"
#     false
#   end

#   def add_queue(ip, username, password, payload)
#     uri = URI("http://#{ip}/rest/queue/simple/add")
#     req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
#     req.basic_auth(username, password)
#     req.body = payload.to_json

#     res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

#     unless res.is_a?(Net::HTTPSuccess)
#       raise "Failed to add queue: #{res.body}"
#     end
#   end
# end


require 'net/http'
require 'uri'
require 'json'

class ContentionRatioJob
  include Sidekiq::Job
  queue_as :default

  def perform
    NasRouter.all.each do |router|
      begin
        router_ip       = router.ip_address
        router_username = router.username
        router_password = router.password

        # Step 1: Fetch active PPPoE users
        active_users = fetch_active_users(router_ip, router_username, router_password)
        active_usernames = active_users.map { |u| u['name'].to_s.strip }
        Rails.logger.info "ContentionRatioJob Active usernames: #{active_usernames}"

        # Step 2: Always fetch existing queues
        existing_queues = fetch_all_queues(router_ip, router_username, router_password)
        Rails.logger.info "ContentionRatioJob Existing queues: #{existing_queues.map { |q| q['name'] }}"

        # Step 3: Remove queues with no matching active user
        existing_queues.each do |queue|
          queue_name = queue['name']
          Rails.logger.info "ContentionRatioJob Checking queue: #{queue_name}"

          pppoe_username = queue_name.split('_')[1].to_s.strip

          unless active_usernames.include?(pppoe_username)
            Rails.logger.info "ContentionRatioJob Removing stale queue: #{queue_name} (pppoe_username: #{pppoe_username})"
            remove_queue(router_ip, router_username, router_password, queue_name)
          end
        end


firewall_address_list = fetch_ip_firewal_adres_list(router_ip, router_username, router_password)

# Only consider entries in 'aitechs_blocked_list'
blocked_entries = firewall_address_list.select { |entry| entry['list'] == 'aitechs_blocked_list' }
blocked_ips = blocked_entries.map { |entry| entry['address'].to_s.strip }

Rails.logger.info "[ContentionRatioJob] IPs in aitechs_blocked_list: #{blocked_ips}"

# Remove IPs from aitechs_blocked_list if not currently active
blocked_entries.each do |entry|
  ip = entry['address'].to_s.strip
  unless active_users_ip.include?(ip)
    remove_from_address_list(router_ip, router_username, router_password, entry['.id'], ip)
  end
end


        next if active_users.blank?
        Rails.logger.info "ContentionRatioJob Active users: #{active_users}"

        active_users.each do |user|
          pppoe_username = user['name'].to_s.strip
          subscription   = Subscription.find_by(ppoe_username: pppoe_username)
          next unless subscription

          package = Package.find_by(name: subscription.package_name)
          next unless package&.aggregation.present?

          # Count active users with same package
          same_package_users = active_users.count do |u|
            sub = Subscription.find_by(ppoe_username: u['name'].to_s.strip)
            sub&.package_name == subscription.package_name
          end

          same_package_users = [same_package_users, 1].max

          download_limit = package.download_limit.to_f
          upload_limit   = package.upload_limit.to_f

          shared_download = (download_limit / same_package_users).round(2)
          shared_upload   = (upload_limit / same_package_users).round(2)

          queue_name = "queue_#{pppoe_username}"
          target_ip  = subscription.ip_address
          next if target_ip.blank?

          if queue_exists?(router_ip, router_username, router_password, queue_name)
            Rails.logger.info "[ContentionRatioJob] Queue exists for #{queue_name}, skipping."
            next
          end

          payload = {
            name: queue_name,
            target: target_ip,
            "max-limit": "#{shared_upload}M/#{shared_download}M",
            "burst-threshold": "#{package.burst_threshold_upload}M/#{package.burst_threshold_download}M",
            "burst-limit": "#{package.burst_upload_speed}M/#{package.burst_download_speed}M",
            "burst-time": "#{package.burst_time}/#{package.burst_time}",
            comment: subscription.subscriber.name
          }

          add_queue(router_ip, router_username, router_password, payload)
          Rails.logger.info "[ContentionRatioJob] Queue added for #{queue_name}"
        end

      rescue => e
        Rails.logger.info "[ContentionRatioJob] Error for router #{router.name}: #{e.message}"
      end
    end
  end

  private

  def fetch_active_users(ip, username, password)
    uri = URI("http://#{ip}/rest/ppp/active")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  rescue => e
    Rails.logger.info "[ContentionRatioJob] Failed to fetch active users: #{e.message}"
    []
  end

  def fetch_all_queues(ip, username, password)
    uri = URI("http://#{ip}/rest/queue/simple")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  rescue => e
    Rails.logger.info "[ContentionRatioJob] Failed to fetch queues: #{e.message}"
    []
  end



  def fetch_ip_firewal_adres_list(ip, username, password)
    uri = URI("http://#{ip}/rest/ip/firewall/address-list")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  rescue => e
    Rails.logger.info "[ContentionRatioJob] Failed to fetch adres list: #{e.message}"
    []
  end


  def queue_exists?(ip, username, password, queue_name)
    uri = URI("http://#{ip}/rest/queue/simple/find?name=#{URI.encode_www_form_component(queue_name)}")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body).any?
  rescue => e
    Rails.logger.info "[ContentionRatioJob] Failed to check queue existence: #{e.message}"
    false
  end

  def add_queue(ip, username, password, payload)
    uri = URI("http://#{ip}/rest/queue/simple/add")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth(username, password)
    req.body = payload.to_json

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    raise "[ContentionRatioJob] Failed to add queue: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end

  def remove_queue(ip, username, password, queue_name)
    queues = fetch_all_queues(ip, username, password)
    queue  = queues.find { |q| q['name'] == queue_name }

    unless queue
      Rails.logger.info "[ContentionRatioJob] Queue #{queue_name} not found, skipping removal."
      return
    end

    queue_id = queue['.id']
    uri = URI("http://#{ip}/rest/queue/simple/remove")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth(username, password)
    req.body = { '.id' => queue_id }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    raise "[ContentionRatioJob] Failed to remove queue #{queue_name}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end
end


def remove_from_address_list(ip, username, password, id, address)
  uri = URI("http://#{ip}/rest/ip/firewall/address-list/remove")
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.basic_auth(username, password)
  req.body = { '.id' => id }.to_json

  res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    Rails.logger.info "[ContentionRatioJob] Removed IP #{address} from aitechs_blocked_list"
  else
    Rails.logger.info "[ContentionRatioJob] Failed to remove IP #{address}: #{res.body}"
  end
rescue => e
  Rails.logger.info "[ContentionRatioJob] Exception removing IP #{address}: #{e.message}"
end

