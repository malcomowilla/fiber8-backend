class AddDescriptionToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :description, :string
  end
end
