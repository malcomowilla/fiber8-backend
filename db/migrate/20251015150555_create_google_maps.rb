class CreateGoogleMaps < ActiveRecord::Migration[7.2]
  def change
    create_table :google_maps do |t|
      t.string :api_key
      t.integer :account_id

      t.timestamps
    end
  end
end
