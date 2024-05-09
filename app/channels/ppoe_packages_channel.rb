class PpoePackagesChannel < ApplicationCable::Channel
  # def subscribed
  #   stream_from "PpoePackagesChannel"

  #   broadcast_packages

  # end

  # def broadcast_packages


  #     @packages = PPoePackage.all
  #     packages = @packages.map { |package| package.as_json }
  
  #     ActionCable.server.broadcast 'PpoePackagesChannel', packages
    

  # end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
