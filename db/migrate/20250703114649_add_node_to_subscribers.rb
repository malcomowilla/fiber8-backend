class AddNodeToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :node, :string
  end
end
