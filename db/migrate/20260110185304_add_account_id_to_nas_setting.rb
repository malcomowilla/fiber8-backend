class AddAccountIdToNasSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_settings, :account_id, :integer
  end
end
