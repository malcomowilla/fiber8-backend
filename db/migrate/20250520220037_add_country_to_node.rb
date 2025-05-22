class AddCountryToNode < ActiveRecord::Migration[7.2]
  def change
    add_column :nodes, :country, :string
  end
end
