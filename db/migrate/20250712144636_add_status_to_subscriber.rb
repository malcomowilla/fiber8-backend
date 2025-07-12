class AddStatusToSubscriber < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :status, :string
  end
end
