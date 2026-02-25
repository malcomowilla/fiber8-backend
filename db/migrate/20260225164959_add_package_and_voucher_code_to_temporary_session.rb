class AddPackageAndVoucherCodeToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :hotspot_package, :string
    add_column :temporary_sessions, :voucher_code, :string
  end
end
