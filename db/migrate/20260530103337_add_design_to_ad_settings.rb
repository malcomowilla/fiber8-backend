class AddDesignToAdSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :ad_settings, :link_type, :string
    add_column :ad_settings, :design_background, :string
    add_column :ad_settings, :design_config, :text
  end
end
