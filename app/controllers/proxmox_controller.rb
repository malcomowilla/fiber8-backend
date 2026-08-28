# app/controllers/proxmox_controller.rb

class ProxmoxController < ApplicationController

  # GET /api/proxmox/nodes
  def nodes
    service = ProxmoxService.new
    nodes = service.nodes

    render json: { nodes: nodes }
  end

  # GET /api/proxmox/nodes/:node/status
  def node_status
    service = ProxmoxService.new
    status = service.node_status(params[:node])

    render json: { status: status }
  end

  # GET /api/proxmox/nodes/:node/vms
  def vms
    service = ProxmoxService.new
    vms = service.vms(params[:node])

    render json: { vms: vms }
  end

  # GET /api/proxmox/nodes/:node/containers
  def containers
    service = ProxmoxService.new
    containers = service.containers(params[:node])

    render json: { containers: containers }
  end

  # GET /api/proxmox/dashboard
  # Returns everything in one call
  def dashboard
    service = ProxmoxService.new
    nodes = service.nodes || []

    dashboard_data = nodes.map do |node|
      node_name = node["node"]
      {
        node: node_name,
        status: node["status"],
        cpu: node["cpu"],
        maxcpu: node["maxcpu"],
        mem: node["mem"],
        maxmem: node["maxmem"],
        disk: node["disk"],
        maxdisk: node["maxdisk"],
        uptime: node["uptime"],
        vms: service.vms(node_name) || [],
        containers: service.containers(node_name) || []
      }
    end

    render json: { dashboard: dashboard_data }
  end
end