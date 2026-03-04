class AddIndexToSessionTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_index :temporary_sessions, :session, unique: true
  end
end
