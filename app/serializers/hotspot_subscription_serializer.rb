class HotspotSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :ip_address, :start_time, :up_time, :download, :upload, :account_id
end
