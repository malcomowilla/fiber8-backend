class AddDefaultTemplateToHotspotTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_templates, :default_template, :boolean, default: false
  end
end
