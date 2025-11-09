json.extract! ad, :id, :title, :description, :business_name, :business_type, :offer_text, :discount, :cat_text, :background_color, :text_color, :image, :imagePreview, :target_url, :is_active, :account_id, :created_at, :updated_at
json.url ad_url(ad, format: :json)
