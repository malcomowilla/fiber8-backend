class CreateAds < ActiveRecord::Migration[7.2]
  def change
    create_table :ads do |t|
      t.string :title
      t.string :description
      t.string :business_name
      t.string :business_type
      t.string :offer_text
      t.string :discount
      t.string :cat_text
      t.string :background_color
      t.string :text_color
      t.string :image
      t.string :imagePreview
      t.string :target_url
      t.boolean :is_active
      t.integer :account_id

      t.timestamps
    end
  end
end
