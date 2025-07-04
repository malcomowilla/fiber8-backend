class AddIpToActivtyLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :activty_logs, :ip, :string
  end
end
