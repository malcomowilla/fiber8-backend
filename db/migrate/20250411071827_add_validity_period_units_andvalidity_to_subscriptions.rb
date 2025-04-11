class AddValidityPeriodUnitsAndvalidityToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :validity_period_units, :string
    add_column :subscriptions, :validity, :string
  end
end
