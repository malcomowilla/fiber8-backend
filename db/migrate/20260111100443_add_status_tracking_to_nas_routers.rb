class AddStatusTrackingToNasRouters < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :last_status, :string
    add_column :nas_routers, :last_status_changed_at, :datetime
    add_column :nas_routers, :last_notification_sent_at, :datetime
  end
end
