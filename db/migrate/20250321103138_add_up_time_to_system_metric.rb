class AddUpTimeToSystemMetric < ActiveRecord::Migration[7.2]
  def change
    add_column :system_metrics, :uptime, :string
  end
end
