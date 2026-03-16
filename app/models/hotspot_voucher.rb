class HotspotVoucher < ApplicationRecord

  acts_as_tenant(:account)
  
  # after_commit :broadcast_hotspot_voucher_stats, on: [:create, :update, :destroy] 
  # after_commit :broadcast_hotspot_voucher_status, on: [:create, :update, :destroy]
after_commit :clear_cache
has_one :hotspot_mpesa_revenue
belongs_to :hotspot_package, optional: true
has_many :temporary_sessions, dependent: :destroy
after_commit :broadcast_if_online, on: [:update]


def clear_cache
  Rails.cache.delete("hotspot_vouchers_index_#{account.id}")
end



  def online?
    RadAcct.where(
      acctstoptime: nil,
      username: voucher,
      # framedprotocol: ''
    ).where('acctupdatetime > ?', 3.minutes.ago).exists?
  end



def broadcast_if_online
  if online?
    VoucherChannel.broadcast_to(account, {
      type: "voucher_online",
     is_online: true,
     voucher: voucher,
     id: id
     
    })
  end
end

  # def broadcast_hotspot_voucher_status
  #   voucher_status = {
  #     expired: HotspotVoucher.where(status: 'expired').count,
  #     active: HotspotVoucher.where(status: 'active').count,
  #     used: HotspotVoucher.where(status: 'used').count,
  #   }

  #   VoucherChannel.broadcast_to(account, voucher_status)
  # end

  # def broadcast_hotspot_voucher_stats

  #   voucher_stats = {
  #   vouchers: HotspotVoucher.all.map { |v| HotspotVoucherSerializer.new(v).as_json }
  # }


  #         # vouchers: HotspotVoucher.all

  #   VoucherChannel.broadcast_to(account, voucher_stats)

  # end
  
end
