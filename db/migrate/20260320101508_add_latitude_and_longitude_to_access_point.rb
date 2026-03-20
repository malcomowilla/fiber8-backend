class AddLatitudeAndLongitudeToAccessPoint < ActiveRecord::Migration[7.2]
  def change
    add_column :access_points, :latitude, :string
    add_column :access_points, :longitude, :string
  end
end
