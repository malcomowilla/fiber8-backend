class AddLocationNameAndLatitudeLongitudeToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :location_name, :string
    add_column :subscribers, :latitude, :string
    add_column :subscribers, :longitude, :string
  end
end
