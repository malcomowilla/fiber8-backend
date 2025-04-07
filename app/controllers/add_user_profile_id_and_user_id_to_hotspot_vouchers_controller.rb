class AddUserProfileIdAndUserIdToHotspotVouchersController < ApplicationController
  def user_manager_user_id
  end

  def user_profile_id
  end
end


# server {
#     listen 443 ssl;
#     server_name ;

#     ssl_certificate /etc/letsencrypt/live/aitechs.co.ke/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/aitechs.co.ke/privkey.pem;

#     location / {
#         proxy_pass http:///; # Local IP of MikroTik
#         proxy_http_version 1.1;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#         proxy_set_header Connection "";
#     }
# }
