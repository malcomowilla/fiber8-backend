class AddStatusToAds < ActiveRecord::Migration[7.2]
  def change
    add_column :ads, :status, :string
  end
end
