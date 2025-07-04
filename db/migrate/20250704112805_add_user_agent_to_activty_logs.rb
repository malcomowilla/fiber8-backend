class AddUserAgentToActivtyLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :activty_logs, :user_agent, :string
  end
end
