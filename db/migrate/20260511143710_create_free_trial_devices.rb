class CreateFreeTrialDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :free_trial_devices do |t|
      t.string :mac_address
      t.integer :account_id
      t.string :package
      t.datetime :used_at

      t.timestamps
    end
  end
end
