class AddFupToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :fup_data_unit, :string
    add_column :packages, :fup_data_limit, :string
  end
end
