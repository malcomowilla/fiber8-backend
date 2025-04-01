class AddCanReadAndManageHotspotTemplateToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_hotspot_template, :boolean, default: false
    add_column :users, :can_read_hotspot_template, :boolean,  default: false
  end
end









