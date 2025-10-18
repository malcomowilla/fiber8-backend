

class EmailConfiguration
  def self.configure(current_account, current_system_admin)
    # current_account =  current_account 
    if current_account.nil?
      Rails.logger.info "No current account found for super admin. Using fallback email settings."
      set_fallback_settings

    elsif current_system_admin.present?
      Rails.logger.info "configuring system admin email settings."
      email_setting = current_account&.email_setting

      # Rails.application.config.action_mailer.delivery_method = :mailtrap
      # Rails.application.config.action_mailer.mailtrap_settings = {
      #   api_key: "d848f326f33a7aa8db359e399fd7c510"
      # }
      
      Rails.application.config.action_mailer.delivery_method = :smtp
Rails.application.config.action_mailer.smtp_settings = {
  user_name: email_setting.smtp_username,
  password: email_setting.smtp_password,
  address: email_setting.smtp_host,
  domain: 'aitechsent.net',
  port: email_setting.smtp_port,
  authentication: :login,
  # ssl: true,
  # tls: true,
  # enable_starttls_auto: true,
  ssl: true,                      # Enable SSL for port 465
  tls: false 
}







  # Rails.application.config.action_mailer.delivery_method = :mailtrap





      
    elsif current_account.present?
      Rails.logger.info "configuring email settings for super admin."

      configure_for_account(current_account)


    end
  rescue StandardError => e
    Rails.logger.error "Error configuring email settings: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def self.configure_for_account(account)
    email_setting = account&.email_setting

    if email_setting&.api_key.present?
      Rails.logger.info "Configuring Mailtrap with API Key super admin #{account.email_setting.api_key}"
      Rails.application.config.action_mailer.delivery_method = :mailtrap
      Rails.application.config.action_mailer.mailtrap_settings = {
        api_key: account.email_setting.api_key
      }
    elsif email_setting.present?
      Rails.logger.info "Configuring SMTP with Email Settings"
 Rails.logger.info "Configuring Mailtrap with API Key super adminn #{account.email_setting.api_key}"
      # Rails.application.config.action_mailer.delivery_method = :mailtrap
      # Rails.application.config.action_mailer.mailtrap_settings = {
      #   api_key: 'd848f326f33a7aa8db359e399fd7c510'
      # }
     
      # Rails.application.config.action_mailer.delivery_method = :mailtrap
      # Rails.application.config.action_mailer.mailtrap_settings = {
      #   api_key: account.email_setting.api_key
      # }
      Rails.application.config.action_mailer.delivery_method = :smtp
      Rails.application.config.action_mailer.smtp_settings = {
        user_name: email_setting.smtp_username,
        password: email_setting.smtp_password,
        address: email_setting.smtp_host,
        domain: 'aitechsent.net',

        port: email_setting.smtp_port,
        authentication: :login,
        # ssl: true,
        # tls: true,
        # enable_starttls_auto: true
         ssl: true,                      # Enable SSL for port 465
  tls: false  
      }
      
    else 





      
      Rails.application.config.action_mailer.delivery_method = :smtp
      Rails.application.config.action_mailer.smtp_settings = {
        user_name: email_setting.smtp_username,
        password: email_setting.smtp_password,
        address: email_setting.smtp_host,
        port: email_setting.smtp_port,
        domain: 'aitechsent.net',

        authentication: :login,
        ssl: true,                      # Enable SSL for port 465
  tls: false  
        # ssl: true,
        # tls: true,
        # enable_starttls_auto: true
      }
      
      # Rails.logger.warn "No email settings found for account. Using fallback."
      # set_fallback_settings
    end
  end

  
end
