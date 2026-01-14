class AddPaidToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :paid, :boolean
  end
end
