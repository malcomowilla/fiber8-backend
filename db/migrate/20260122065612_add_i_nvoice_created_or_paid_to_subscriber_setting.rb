class AddINvoiceCreatedOrPaidToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :invoice_created_or_paid, :boolean, default: false
  end
end




