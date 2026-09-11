
class SyncPackageJob < ApplicationJob
  queue_as :default

  def perform(package_id)
    package = Package.find(package_id)
    package.package_routers.each do |pr|
      MikrotikProfileSyncService.sync(package, pr)
    rescue MikrotikProfileSyncService::SyncError
      next # already recorded on package_router via sync_error
    end
  end
end