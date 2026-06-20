class CreateMaintenanceSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :maintenance_settings do |t|
      t.boolean :enabled
      t.datetime :until_time
      t.text :message
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
