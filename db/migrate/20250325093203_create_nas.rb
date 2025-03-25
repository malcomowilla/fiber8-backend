class CreateNas < ActiveRecord::Migration[7.2]
  def change
    create_table :nas do |t|
      t.string :name
      t.string :shortname
      t.string :ipaddr
      t.string :secret
      t.string :nas_type
      t.integer :ports

      t.timestamps
    end
  end
end
