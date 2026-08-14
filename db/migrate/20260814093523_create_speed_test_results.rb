class CreateSpeedTestResults < ActiveRecord::Migration[7.2]
  def change
    create_table :speed_test_results do |t|
      t.references :account, null: false, index: true
      t.references :subscriber, null: false, index: true
      t.references :nas_router, null: true, index: true

      t.float   :download_mbps, null: false
      t.float   :upload_mbps,   null: false
      t.integer :ping_ms
      t.integer :jitter_ms

      t.float   :plan_speed_mbps
      t.float   :percent_of_plan
      t.string  :status, default: 'healthy' # healthy | warning | critical

      t.datetime :tested_at, null: false

      t.timestamps
    end

    add_index :speed_test_results, [:subscriber_id, :tested_at]
  end
end
