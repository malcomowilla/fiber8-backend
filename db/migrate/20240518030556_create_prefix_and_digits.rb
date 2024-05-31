class CreatePrefixAndDigits < ActiveRecord::Migration[7.1]
  def change
    create_table :prefix_and_digits do |t|
      t.string :prefix
      t.integer :minimum_digits

      t.timestamps
    end
  end
end
