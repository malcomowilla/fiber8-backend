class CreateGeneralSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :general_settings do |t|
      t.string :title
      t.string :timezone
      t.string :allowed_ips, array: true, default: []
      t.integer :account_id

      t.timestamps
    end
  end
end











