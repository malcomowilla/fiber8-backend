class AddPackageNameToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :package_name, :string
  end
end
