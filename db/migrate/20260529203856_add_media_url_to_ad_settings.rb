class AddMediaUrlToAdSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :ad_settings, :media_url, :string
  end
end
