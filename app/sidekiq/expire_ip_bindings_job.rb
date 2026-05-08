# app/jobs/expire_ip_bindings_job.rb

require 'net/http'
require 'uri'
require 'json'

class ExpireIpBindingsJob
  include Sidekiq::Job
  queue_as :default

  sidekiq_options lock: :until_executed, lock_timeout: 0

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        expired = IpBinding.where(account_id: tenant.id)
                           .where.not(expiry: [nil, ''])
                           .where('expiry <= ?', Time.current)

        expired.each do |binding|
          begin
            router = find_nas_router(binding, tenant)

            unless router
              Rails.logger.info "[ExpireIpBindingsJob] No router found for binding #{binding.id}, deleting DB record only."
              binding.destroy!
              next
            end

            # 1. Remove MAC bypass from MikroTik hotspot
            mikrotik_remove_binding(router, binding)

            # 2. Remove queue if a package is set
            if binding.package.present?
              mikrotik_remove_queue_for_binding(router, binding)
            end

            # 3. Delete DB record
            binding.destroy!

            Rails.logger.info "[ExpireIpBindingsJob] Expired and removed binding #{binding.id} (#{binding.name}) for tenant #{tenant.subdomain}"

          rescue => e
            Rails.logger.info "[ExpireIpBindingsJob] Error processing binding #{binding.id}: #{e.message}"
          end
        end
      end
    end
  end

  private

  def find_nas_router(binding, tenant)
    if binding.router_id.present?
      NasRouter.find_by(id: binding.router_id, account_id: tenant.id)
    else
      NasRouter.find_by(name: binding.router, account_id: tenant.id)
    end
  end

  # ── MikroTik: remove hotspot ip-binding by MAC ──────────────────────────────

  def mikrotik_remove_binding(router, binding)
    mac        = binding.mac.upcase.gsub('-', ':')
    remove_cmd = "/ip hotspot ip-binding remove [find mac-address=\"#{mac}\"]"

    Net::SSH.start(
      router.ip_address,
      router.username,
      password:        router.password.to_s,
      auth_methods:    %w[password keyboard-interactive],
      non_interactive: true,
      timeout:         15,
      verify_host_key: :never
    ) do |ssh|
      output = ssh.exec!(remove_cmd).to_s.strip
      Rails.logger.info "[ExpireIpBindingsJob] SSH remove binding #{binding.mac}: #{output}"
    end
  rescue => e
    Rails.logger.info "[ExpireIpBindingsJob] SSH failed removing binding #{binding.mac}: #{e.message}"
  end

  # ── MikroTik: remove simple queue by name (REST) ────────────────────────────

  def binding_queue_name(binding)
    "binding_#{binding.mac.upcase.gsub(':', '')}"
  end

  def mikrotik_remove_queue_for_binding(router, binding)
    queue_name = binding_queue_name(binding)
    base_url   = "http://#{router.ip_address}"

    # 1. Find queue .id
    uri = URI("#{base_url}/rest/queue/simple/find?name=#{URI.encode_www_form_component(queue_name)}")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(router.username, router.password.to_s)

    res = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[ExpireIpBindingsJob] Could not find queue '#{queue_name}': #{res.body}"
      return
    end

    ids = JSON.parse(res.body)
    if ids.empty?
      Rails.logger.info "[ExpireIpBindingsJob] Queue '#{queue_name}' not found, skipping."
      return
    end

    queue_id = ids.first

    # 2. Remove it
    uri2 = URI("#{base_url}/rest/queue/simple/remove")
    req2 = Net::HTTP::Post.new(uri2, 'Content-Type' => 'application/json')
    req2.basic_auth(router.username, router.password.to_s)
    req2.body = { '.id' => queue_id }.to_json

    res2 = Net::HTTP.start(uri2.hostname, uri2.port, open_timeout: 10, read_timeout: 10) do |http|
      http.request(req2)
    end

    if res2.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[ExpireIpBindingsJob] Queue '#{queue_name}' removed on expiry of binding #{binding.id}"
    else
      Rails.logger.info "[ExpireIpBindingsJob] Failed to remove queue '#{queue_name}': #{res2.body}"
    end
  rescue => e
    Rails.logger.info "[ExpireIpBindingsJob] REST error removing queue '#{queue_name}': #{e.message}"
  end
end