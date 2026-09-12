class SyncPackageJob < ApplicationJob
  queue_as :default

  def perform(package_id)
    package = Package.find(package_id)
    MikrotikProfileSyncService.sync(package)
  rescue MikrotikProfileSyncService::SyncError
    # error message is already recorded on package.sync_error by the service
    nil
  end
end