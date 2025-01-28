class CompanySettingSerializer < ActiveModel::Serializer
  # attributes :id, :company_name, :email_info, :contact_info, :agent_email, 
  # :customer_support_phone_number, :customer_support_email





  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper
  attributes :id, :company_name, :contact_info, :email_info, :logo, 
  :customer_support_phone_number, :agent_email, :customer_support_email




  def logo

    
    return unless object.logo.attached?

    # Generate the full URL for the logo
    Rails.application.routes.url_helpers.rails_blob_url(object.logo, host: '102.221.35.116')
  end


end
