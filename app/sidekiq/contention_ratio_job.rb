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
        next if active_users.blank?

        active_users.each do |user|
          pppoe_username = user['name']
          subscription   = Subscription.find_by(ppoe_username: pppoe_username)
          next unless subscription

          package = Package.find_by(name: subscription.package_name, router_name: router.name)
          next unless package&.aggregation.present?

          aggregation_ratio = package.aggregation.to_i
          download_limit    = package.download_limit.to_f
          upload_limit      = package.upload_limit.to_f

          shared_download = (download_limit / aggregation_ratio).round(2)
          shared_upload   = (upload_limit / aggregation_ratio).round(2)

          queue_name = "queue_#{pppoe_username}"
          target_ip  = subscription.ip_address
          next if target_ip.blank?

          # Step 2: Check if queue already exists
          if queue_exists?(router_ip, router_username, router_password, queue_name)
            Rails.logger.info "[ContentionRatioJob] Queue exists for #{queue_name}, skipping."
            next
          end

          # Step 3: Add queue
          payload = {
            name: queue_name,
            target: target_ip,
            "max-limit": "#{shared_upload}M/#{shared_download}M",
            "burst-threshold": "#{package.burst_threshold_upload}/#{package.burst_threshold_download}",
            "burst-limit": "#{package.burst_upload_speed}/#{package.burst_download_speed}",
            "burst-time": package.burst_time.to_s
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
    Rails.logger.info "Failed to fetch active users: #{e.message}"
    []
  end

  def queue_exists?(ip, username, password, queue_name)
    uri = URI("http://#{ip}/rest/queue/simple/find?name=#{queue_name}")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body).any?
  rescue => e
    Rails.logger.info "Failed to check queue #{queue_name} existence: #{e.message}"
    false
  end

  def add_queue(ip, username, password, payload)
    uri = URI("http://#{ip}/rest/queue/simple/add")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth(username, password)
    req.body = payload.to_json

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "Failed to add queue: #{res.body}"
    end
  end
end
