class PlatformBulkSmsSetting < ApplicationRecord
  # No ActsAsTenant — this is deliberately global, one row, system-admin only.
  def self.current
    first_or_create!
  end
end