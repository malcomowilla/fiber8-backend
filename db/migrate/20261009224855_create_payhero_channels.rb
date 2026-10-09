class CreatePayheroChannels < ActiveRecord::Migration[7.2]
   def change
    create_table :payhero_channels do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :channel_type,      null: false   
      t.string  :short_code,        null: false
      t.string  :account_number
      t.string  :description,       null: false
      t.bigint  :payhero_channel_id, null: false 
      t.boolean :is_default,        null: false, default: false
      t.boolean :is_active,         null: false, default: true
      t.timestamps
    end

    add_index :payhero_channels, :payhero_channel_id, unique: true
    add_index :payhero_channels, [:account_id, :is_default]
  end
end
