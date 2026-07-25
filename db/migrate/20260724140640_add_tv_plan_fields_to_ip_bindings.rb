class AddTvPlanFieldsToIpBindings < ActiveRecord::Migration[7.2]
  def change
    add_reference :ip_bindings, :tv_plan, null: true, foreign_key: true
    add_column :ip_bindings, :phone, :string
    add_column :ip_bindings, :source, :string, default: "manual" # manual | tv_plan_purchase
    add_column :ip_bindings, :status, :string, default: "active"
  end
end
