class AddHardwareVersionToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :hardware_version, :string
  end
end
