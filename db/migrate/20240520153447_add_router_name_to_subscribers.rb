class AddRouterNameToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :router_name, :string
  end
end
