class AddPaymentReceivedToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :notify_user_payment_received, :boolean, default: false
  end
end




