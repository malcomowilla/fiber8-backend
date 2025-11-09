class AdSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :business_name,
   :business_type, :offer_text, :discount, :cat_text, :background_color, 
   :text_color, :image, :imagePreview, :target_url, :is_active, :account_id,
   :image_preview, :website, :phone, :email

end
