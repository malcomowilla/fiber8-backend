class RestartCloudflaredIfTunnelMissingJob
    queue_as :default

  include Sidekiq::Job

   def perform
    log_output = `journalctl -u cloudflared -n 100 --no-pager --reverse`

    unless log_output.match?(%r{https://[a-z0-9-]+\.trycloudflare\.com})
      Rails.logger.warn "[Tunnel Monitor] No valid Cloudflare tunnel found. Restarting services..."

      # Restart cloudflared and your backend service
      system("systemctl restart cloudflared")
      system("systemctl restart aitechs-fibe8-backend")

      Rails.logger.info "[Tunnel Monitor] Services restarted successfully."
    else
      Rails.logger.info "[Tunnel Monitor] Tunnel is active. No action needed."
    end
  end
end
