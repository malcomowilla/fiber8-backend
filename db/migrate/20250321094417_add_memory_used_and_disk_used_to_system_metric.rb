class AddMemoryUsedAndDiskUsedToSystemMetric < ActiveRecord::Migration[7.2]
  def change
    add_column :system_metrics, :memory_used, :string
    add_column :system_metrics, :disk_used, :string
  end
end
