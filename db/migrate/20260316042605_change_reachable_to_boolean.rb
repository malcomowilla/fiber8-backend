class ChangeReachableToBoolean < ActiveRecord::Migration[7.2]
  def change
    change_column :access_points, :reachable, :boolean, using: "reachable::boolean", default: false

  end
end
