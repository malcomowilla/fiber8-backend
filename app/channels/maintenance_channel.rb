class MaintenanceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "maintenance_#{params[:subdomain]}"
  end
end