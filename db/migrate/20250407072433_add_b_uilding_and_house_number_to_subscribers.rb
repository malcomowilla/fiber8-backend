class AddBUildingAndHouseNumberToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :buildin_name, :string
    add_column :subscribers, :house_number, :string
  end
end
