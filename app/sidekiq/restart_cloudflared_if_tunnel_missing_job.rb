class RestartCloudflaredIfTunnelMissingJob
  include Sidekiq::Job
  queue_as :default

   def perform
    log_output = `journalctl -u loophole -n 200 --no-page`


    unless log_output.match(%r{https://([a-z0-9\-]+\.loophole\.site)})
      Rails.logger.warn "[Tunnel Monitor] No valid Cloudflare tunnel found. Restarting services..."

      # Restart cloudflared and your backend service
      `systemctl restart loophole`
      # `systemctl restart aitechs-fiber8-backend`

      Rails.logger.info "[Tunnel Monitor] Services restarted successfully."
    else
      Rails.logger.info "[Tunnel Monitor] Tunnel is active. No action needed."
    end


    
  end
end
