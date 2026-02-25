class AddCheckOutRequestIdToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :checkout_request_id, :string
  end
end
