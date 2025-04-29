class AddPackageToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :package, :string
  end
end
