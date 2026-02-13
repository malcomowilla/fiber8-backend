class AddInstallationFeeAndIncludeInstallationFeeToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :include_installation_fee, :boolean, default: false
    add_column :subscriptions, :installation_fee, :string
  end
end




