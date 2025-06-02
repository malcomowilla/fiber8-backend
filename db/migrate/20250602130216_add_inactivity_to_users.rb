class AddInactivityToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_activity_active, :datetime
  end
end
