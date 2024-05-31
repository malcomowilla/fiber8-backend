class RemovePackageFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :package, :string
  end
end
