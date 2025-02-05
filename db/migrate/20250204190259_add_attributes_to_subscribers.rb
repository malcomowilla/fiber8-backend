class AddAttributesToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :last_renewed, :string
    add_column :subscribers, :expires, :datetime
    add_column :subscribers, :online, :boolean
  end
end
