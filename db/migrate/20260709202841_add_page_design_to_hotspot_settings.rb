class AddPageDesignToHotspotSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_settings, :page_design, :jsonb, default: {}, null: false unless column_exists?(:hotspot_settings, :page_design)
    add_column :hotspot_settings, :page_design_published_at, :datetime unless column_exists?(:hotspot_settings, :page_design_published_at)
    add_index :hotspot_settings, :page_design, using: :gin
  end
end
