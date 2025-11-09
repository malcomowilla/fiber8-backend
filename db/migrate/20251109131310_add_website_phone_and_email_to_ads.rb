class AddWebsitePhoneAndEmailToAds < ActiveRecord::Migration[7.2]
  def change
    add_column :ads, :phone, :string
    add_column :ads, :email, :string
    add_column :ads, :website, :string
  end
end
