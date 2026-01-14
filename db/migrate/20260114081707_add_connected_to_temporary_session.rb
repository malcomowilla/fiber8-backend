class AddConnectedToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :connected, :boolean, default: false
  end
end
