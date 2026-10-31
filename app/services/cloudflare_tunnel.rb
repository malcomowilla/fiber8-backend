require 'net/http'
require 'json'
require 'cgi'

class CloudflareTunnel
  class Error < StandardError; end
  BASE = 'https://api.cloudflare.com/client/v4'.freeze

  def self.publish_hostname!(subdomain)
    new.publish_hostname!(subdomain)
  end

  def publish_hostname!(subdomain)
    hostname = "#{subdomain}.#{root_domain}"
    add_ingress_rule(hostname)
    ensure_dns_record(subdomain, hostname)
    hostname
  end

  private

  def add_ingress_rule(hostname)
    path = "/accounts/#{env!('CLOUDFLARE_ACCOUNT_ID')}/cfd_tunnel/#{tunnel_id}/configurations"
    config  = request(:get, path).dig('result', 'config') || {}
    ingress = config['ingress'] || []
    return if ingress.any? { |r| r['hostname'] == hostname } # already published

    catch_all = ingress.find { |r| r['hostname'].nil? } || { 'service' => 'http_status:404' }
    rules     = ingress.reject { |r| r['hostname'].nil? }
    rules << { 'hostname' => hostname, 'service' => env!('CLOUDFLARE_ORIGIN_SERVICE') }

    request(:put, path, { config: config.merge('ingress' => rules + [catch_all]) })
  end

  # The dashboard creates this CNAME automatically; the API does not.
  def ensure_dns_record(subdomain, hostname)
    zone = env!('CLOUDFLARE_ZONE_ID')
    existing = request(:get, "/zones/#{zone}/dns_records?type=CNAME&name=#{CGI.escape(hostname)}")['result']
    return if existing.present?

    request(:post, "/zones/#{zone}/dns_records",
            { type: 'CNAME', name: subdomain, content: "#{tunnel_id}.cfargotunnel.com", proxied: true, ttl: 1 })
  end

  def request(method, path, body = nil)
    uri = URI("#{BASE}#{path}")
    klass = { get: Net::HTTP::Get, put: Net::HTTP::Put, post: Net::HTTP::Post }.fetch(method)
    req = klass.new(uri)
    req['Authorization'] = "Bearer #{env!('CLOUDFLARE_API_TOKEN')}"
    req['Content-Type']  = 'application/json'
    req.body = body.to_json if body

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 20) { |h| h.request(req) }
    json = (JSON.parse(res.body) rescue {})
    unless res.is_a?(Net::HTTPSuccess) && json['success']
      msg = Array(json['errors']).map { |e| e['message'] }.join(', ').presence || "HTTP #{res.code}"
      raise Error, "Cloudflare: #{msg}"
    end
    json
  end

  def tunnel_id   = env!('CLOUDFLARE_TUNNEL_ID')
  def root_domain = ENV.fetch('PLATFORM_ROOT_DOMAIN', 'owitech.co.ke')

  def env!(key)
    ENV[key].presence || raise(Error, "#{key} is not set")
  end
end