class AddPartnerIdToSmsSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :sms_settings, :partnerID, :string
  end
end
