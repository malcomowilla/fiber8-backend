class AddImagePreviewToAd < ActiveRecord::Migration[7.2]
  def change
    add_column :ads, :image_preview, :string
  end
end
