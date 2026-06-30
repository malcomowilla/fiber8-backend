

# # app/jobs/generate_clients_conf_job.rb
# class GenerateClientsConfJob
#   include Sidekiq::Job
#   queue_as :client_conf

#   def perform
#     Rails.logger.info "Generating clients.conf"

#     # File.open('/etc/freeradius/3.0/clients.conf', 'w') do |f|

    
#     # File.open('/etc/freeradius/3.0/clients.conf', 'w') do |f|
#     File.open('/etc/freeradius/3.0/clients.conf', 'w') do |f|
#       Na.find_each do |nas|
#         next if nas.nasname.blank? || nas.secret.blank?

#         f.puts <<~CLIENT
#           client #{nas.shortname.presence || "client_#{nas.id}"} {
#             ipaddr     = #{nas.nasname}
#             secret     = #{nas.secret}
#             require_message_authenticator = no
#           }
#         CLIENT
#       end
#     end
#   end
# end









# app/jobs/generate_clients_conf_job.rb
class GenerateClientsConfJob
  include Sidekiq::Job
  queue_as :client_conf

  def perform
    Rails.logger.info "Generating clients.conf"
    
    File.open('/etc/freeradius/3.0/clients.conf', 'w') do |f|
      Na.find_each do |nas|
        next if nas.nasname.blank? || nas.secret.blank?

        f.puts <<~CLIENT
          client #{nas.shortname.presence || "client_#{nas.id}"} {
            ipaddr     = #{nas.nasname}
            secret     = #{nas.secret}
            require_message_authenticator = no
          }
        CLIENT
      end
    end

    # 👇 ADD THIS HOOK LINE AFTER THE FILE IS CLOSED
    # This creates a zero-byte file that your host can watch to run a automated reload command
    FileUtils.touch('/etc/freeradius/3.0/.reload_trigger') rescue nil
  end
end









