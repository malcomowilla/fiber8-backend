class AddLastStatusChangedAtAndLastNotificationSentAtToAccessPoint < ActiveRecord::Migration[7.2]
  def change
    add_column :access_points, :last_status_changed_at, :datetime
    add_column :access_points, :last_notification_sent_at, :datetime
  end
end
