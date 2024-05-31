class AddRouterNameToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :router_name, :string
  end
end
