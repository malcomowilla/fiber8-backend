class CreatePPoePackages < ActiveRecord::Migration[7.1]
  def change
    create_table :p_poe_packages do |t|
      t.string :name
      t.integer :price
      t.string :download_limit
      t.string :upload_limit
      t.integer :validity

      t.timestamps
    end
  end
end
