class CreateAdSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :ad_settings do |t|
      t.boolean :enabled
      t.boolean :to_right
      t.boolean :to_left
      t.boolean :to_top
      t.integer :account_id

      t.timestamps
    end
  end
end
