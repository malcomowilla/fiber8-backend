class CreateGracePeriodSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :grace_period_settings do |t|
      t.integer :grace_period_value, null: false, default: 1
      t.string  :grace_period_unit, null: false, default: 'days' # minutes | hours | days
      t.boolean :enabled, null: false, default: true
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
    # add_index :grace_period_settings, :account_id, unique: true
  end
end
