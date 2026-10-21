class AddPbxIdToSipExtensions < ActiveRecord::Migration[7.2]
  def up
    add_column :sip_extensions, :pbx_id, :string
    # Existing rows keep their current PJSIP id (legacy, untagged). Recreate them to get the suffix.
    execute "UPDATE sip_extensions SET pbx_id = extension WHERE pbx_id IS NULL"
    change_column_null :sip_extensions, :pbx_id, false
    add_index :sip_extensions, :pbx_id, unique: true
    add_index :sip_extensions, [:account_id, :extension], unique: true
  end

  def down
    remove_index :sip_extensions, [:account_id, :extension]
    remove_index :sip_extensions, :pbx_id
    remove_column :sip_extensions, :pbx_id
  end
end
