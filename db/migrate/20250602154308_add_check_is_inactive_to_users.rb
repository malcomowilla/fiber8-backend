class AddCheckIsInactiveToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :check_is_inactive, :boolean
  end
end
