class AddNasRouterToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :nas_router, :string

  end
end
