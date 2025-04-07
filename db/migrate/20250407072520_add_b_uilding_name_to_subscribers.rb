class AddBUildingNameToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :building_name, :string
  end
end
