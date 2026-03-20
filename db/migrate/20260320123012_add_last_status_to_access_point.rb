class AddLastStatusToAccessPoint < ActiveRecord::Migration[7.2]
  def change
    add_column :access_points, :last_status, :string
  end
end
