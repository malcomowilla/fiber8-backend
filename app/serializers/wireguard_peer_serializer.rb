class WireguardPeerSerializer < ActiveModel::Serializer
  attributes :id, :allowed_ips, :persistent_keepalive,
             :private_ip, :status, :created_at, :updated_at




             def created_at
               object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
             end



              def updated_at
               object.updated_at.strftime("%B %d, %Y at %I:%M %p") if object.updated_at.present?
             end


end
