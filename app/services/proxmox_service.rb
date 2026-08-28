# app/services/proxmox_service.rb

class ProxmoxService
  BASE_URL = "https://#{ENV['PROXMOX_HOST']}:8006/api2/json"

  def initialize
    @token_id = ENV['PROXMOX_TOKEN_ID']
    @token_secret = ENV['PROXMOX_TOKEN_SECRET']
  end

  def nodes
    get("/nodes")
  end

  def node_status(node)
    get("/nodes/#{node}/status")
  end

  # ── VMs ──────────────────────────────────────────────────────
  def vms(node)
    get("/nodes/#{node}/qemu")
  end

  def vm_status(node, vmid)
    get("/nodes/#{node}/qemu/#{vmid}/status/current")
  end

  # ── Containers ───────────────────────────────────────────────
  def containers(node)
    get("/nodes/#{node}/lxc")
  end

  # ── Storage ──────────────────────────────────────────────────
  def storage(node)
    get("/nodes/#{node}/storage")
  end

  # ── Network ──────────────────────────────────────────────────
  def network(node)
    get("/nodes/#{node}/network")
  end

  # ── Tasks ────────────────────────────────────────────────────
  def tasks(node)
    get("/nodes/#{node}/tasks")
  end

  private

  def get(path)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "PVEAPIToken=#{@token_id}=#{@token_secret}"
  request["Content-Type"] = "application/json"

  response = http.request(request)

  Rails.logger.info "Proxmox GET #{path} -> #{response.code}"
  Rails.logger.info "Proxmox body: #{response.body}" unless response.code.to_i == 200

  data = JSON.parse(response.body)
  data["data"]
rescue => e
  Rails.logger.error "Proxmox API error (#{path}): #{e.class} #{e.message}"
  nil
end
end