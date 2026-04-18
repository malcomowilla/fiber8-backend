class AddSubscriberIdToSystemAdminSm < ActiveRecord::Migration[7.2]
  def change
    add_column :system_admin_sms, :subscriber_id, :integer
  end
end
