class AddFupEnabledToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :fup_enabled, :boolean, default: false
  end
end
