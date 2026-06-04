class AddWidthAndHeightToAdSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :ad_settings, :design_canvas_w, :string
    add_column :ad_settings, :design_canvas_h, :string
  end
end
