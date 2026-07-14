class AddUseRadiusToNasSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_settings, :use_radius, :boolean
  end
end
