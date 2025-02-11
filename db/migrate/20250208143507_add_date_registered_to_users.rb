class AddDateRegisteredToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :date_registered, :datetime
  end
end
