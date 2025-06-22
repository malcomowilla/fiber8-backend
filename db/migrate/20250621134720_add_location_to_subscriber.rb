class AddLocationToSubscriber < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :location, :text, array: true, default: []
  end
end





