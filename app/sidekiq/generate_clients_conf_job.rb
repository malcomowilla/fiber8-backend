

# app/jobs/generate_clients_conf_job.rb
class GenerateClientsConfJob
  include Sidekiq::Job
  queue_as :client_conf

  def perform
    Rails.logger.info "Generating clients.conf"

 Rails.logger.info "[DeleteSessionJob] Sync sessions started"

    online_ips = RadAcct.where(acctstoptime: nil, framedprotocol: '').where('acctupdatetime > ?', 3.minutes.ago).pluck(:framedipaddress).uniq.map(&:to_s)
      

   

      offline_ips = RadAcct.where.not(acctstoptime: nil, framedprotocol: '').where.not('acctupdatetime > ?', 3.minutes.ago).pluck(:framedipaddress).uniq.map(&:to_s)
      
      

    Rails.logger.info "[DeleteSessionJob] Online IPs: #{online_ips.inspect}"

    updated_online = TemporarySession
      .where(ip:  online_ips)
      # .where(connected: true)
      .update_all(connected: true, updated_at: Time.current)

    Rails.logger.info "[DeleteSessionJob] Marked ONLINE: #{updated_online}"

    updated_offline = TemporarySession
      .where(ip: offline_ips)
      #  .where(connected: false)
      .update_all(connected: false, updated_at: Time.current)

    Rails.logger.info "[DeleteSessionJob] Marked OFFLINE: #{updated_offline}"


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
  end
end


















