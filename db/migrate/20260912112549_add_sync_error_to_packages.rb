class AddSyncErrorToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :sync_error, :string unless column_exists?(:packages, :sync_error)
  end
end
