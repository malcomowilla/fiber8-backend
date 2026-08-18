class MaintenanceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "maintenance"
  end
end