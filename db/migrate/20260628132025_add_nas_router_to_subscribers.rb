class AddNasRouterToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :nas_router, :string
  end
end
