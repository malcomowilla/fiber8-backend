class AddInboundFieldsToCallCenterSettings < ActiveRecord::Migration[7.2]
  def change
     add_column :call_center_settings, :did_numbers, :string
    add_column :call_center_settings, :unreachable_message, :text
  end
end
