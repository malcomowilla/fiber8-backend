class AddMacToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :mac, :string
  end
end
