class AddSoftwareVersionToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :software_version, :string
  end
end
