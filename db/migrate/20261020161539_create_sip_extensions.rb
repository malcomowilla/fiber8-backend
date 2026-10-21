class CreateSipExtensions < ActiveRecord::Migration[7.2]
  def change
    create_table :sip_extensions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :extension, null: false
      t.string :name, null: false
      t.string :transport, null: false, default: "transport-udp"
      t.boolean :enabled, null: false, default: true

      t.timestamps

      # Extension IDs must be globally unique for Asterisk.
      t.index :extension, unique: true
    end
  end
end