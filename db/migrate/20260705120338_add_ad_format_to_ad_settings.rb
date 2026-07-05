class AddAdFormatToAdSettings < ActiveRecord::Migration[7.2]
  def change
        add_column :ad_settings, :ad_format, :string, default: "image"

  end
end
