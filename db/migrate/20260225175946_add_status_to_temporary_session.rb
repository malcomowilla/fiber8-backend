class AddStatusToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :status, :string
  end
end
