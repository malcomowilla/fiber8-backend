class AddCpuUsedUptimeAndRamUsedToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :uptime, :string
    add_column :onus, :cpu_used, :string
    add_column :onus, :ram_used, :string
  end
end
