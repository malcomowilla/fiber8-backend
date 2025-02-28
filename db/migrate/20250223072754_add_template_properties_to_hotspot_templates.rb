class AddTemplatePropertiesToHotspotTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_templates, :sleekspot, :boolean, default: false
    add_column :hotspot_templates, :attractive, :boolean, default: false
    add_column :hotspot_templates, :clean, :boolean, default: false
    add_column :hotspot_templates, :default, :boolean, default: false
    add_column :hotspot_templates, :flat, :boolean, default: false
    add_column :hotspot_templates, :minimal, :boolean, default: false
    add_column :hotspot_templates, :simple, :boolean, default: false
  end
end






