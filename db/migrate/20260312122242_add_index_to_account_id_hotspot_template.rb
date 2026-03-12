class AddIndexToAccountIdHotspotTemplate < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_templates, :account_id
  end
end
