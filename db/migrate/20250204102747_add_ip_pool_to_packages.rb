class AddIpPoolToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :ip_pool, :string
  end
end
