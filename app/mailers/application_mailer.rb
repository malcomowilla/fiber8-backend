class ApplicationMailer < ActionMailer::Base
 


  layout "mailer"

  private

  # Helper method to fetch the dynamic sender email based on the current tenant
  def tenant_sender_email
   
    
    ActsAsTenant.with_tenant(ActsAsTenant.current_tenant) do
      Rails.logger.debug "Tenant inside mailer: #{EmailSetting.first.sender_email}"
      # ActsAsTenant.current_tenant&.email_setting&.sender_email  
      EmailSetting.first.sender_email
    end
    
  end
end
