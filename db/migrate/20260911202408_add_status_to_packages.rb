class AddStatusToPackages < ActiveRecord::Migration[7.2]
 def change
    add_column :packages, :status, :string, default: 'active' unless column_exists?(:packages, :status)
  end
end
