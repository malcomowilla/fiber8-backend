class HotspotVoucher < ApplicationRecord

  acts_as_tenant(:account)
  # after_commit :broadcast_hotspot_voucher_stats, on: [:create, :update, :destroy] 
  after_commit :broadcast_hotspot_voucher_status, on: [:create, :update, :destroy]
after_commit :clear_cache

def clear_cache
  Rails.cache.delete("hotspot_vouchers_index")
end





  def broadcast_hotspot_voucher_status
    voucher_status = {
      expired: HotspotVoucher.where(status: 'expired').count,
      active: HotspotVoucher.where(status: 'active').count,
      used: HotspotVoucher.where(status: 'used').count,
    }

    VoucherChannel.broadcast_to(account, voucher_status)
  end

  # def broadcast_hotspot_voucher_stats

  #   voucher_stats = {
  #   vouchers: HotspotVoucher.all.map { |v| HotspotVoucherSerializer.new(v).as_json }
  # }


  #         # vouchers: HotspotVoucher.all

  #   VoucherChannel.broadcast_to(account, voucher_stats)

  # end
  
end
