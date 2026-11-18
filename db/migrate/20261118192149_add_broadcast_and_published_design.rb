class AddBroadcastAndPublishedDesign < ActiveRecord::Migration[7.2]
   def change
    add_column :hotspot_settings, :broadcast_message, :text
    add_column :hotspot_settings, :broadcast_enabled, :boolean, default: false, null: false
    add_column :hotspot_settings, :broadcast_level, :string, default: "warning", null: false
    add_column :hotspot_settings, :broadcast_updated_at, :datetime

    add_column :nas_routers, :published_page_design, :jsonb
    add_column :nas_routers, :page_published_at, :datetime
  end
end
