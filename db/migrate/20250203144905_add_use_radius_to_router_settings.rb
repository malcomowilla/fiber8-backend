class AddUseRadiusToRouterSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :router_settings, :use_radius, :boolean, default: false
  end
end
