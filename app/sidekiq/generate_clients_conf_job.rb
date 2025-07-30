

# app/jobs/generate_clients_conf_job.rb
class GenerateClientsConfJob
  include Sidekiq::Job
  queue_as :default

  def perform
    
    Rails.logger.info "Generating clients.conf"
    File.open('/etc/freeradius/3.0/clients.conf', 'w') do |f|
      Na.find_each do |nas|
        # next if nas.nasname.blank? || nas.secret.blank?

        f.puts <<~CLIENT
          client #{nas.shortname.presence || "client_#{nas.id}"} {
            ipaddr     = #{nas.nasname}
            secret     = #{nas.secret}
            require_message_authenticator = no
          }
        CLIENT
      end
    end
  end
end
