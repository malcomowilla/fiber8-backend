class CreateTemplateLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :template_locations do |t|
      t.string :name
      t.string :type
      t.string :location
      t.integer :account_id

      t.timestamps
    end
  end
end
