class CreateSystemMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :system_metrics do |t|
      t.string :cpu_usage
      t.string :memory_total
      t.string :memory_free
      t.string :disk_total
      t.string :disk_free
      t.string :load_average
      t.integer :account_id

      t.timestamps
    end
  end
end
