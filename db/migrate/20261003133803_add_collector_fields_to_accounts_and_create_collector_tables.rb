class AddCollectorFieldsToAccountsAndCreateCollectorTables < ActiveRecord::Migration[7.2]
  def change
    # existing ISP accounts become account_type "isp", status "active"
    add_column :accounts, :account_type, :string, default: "isp", null: false
    add_column :accounts, :company_name, :string
    add_column :accounts, :status, :string, default: "active", null: false
    add_column :accounts, :signup_ip, :string
    add_index :accounts, :account_type
 
    create_table :collector_buildings do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :area, null: false
      t.integer :units
      t.timestamps
    end
 
    create_table :collector_customers do |t|
      t.references :account, null: false, foreign_key: true
      t.references :collector_building, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :phone
      t.string  :unit, null: false
      t.integer :packs_paid, null: false, default: 0
      t.timestamps
    end
 
    create_table :collector_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :collector_customer, foreign_key: true
      t.string  :kind, null: false # "payment" or "withdrawal"
      t.string  :label, null: false
      t.decimal :gross, precision: 12, scale: 2, null: false, default: 0
      t.decimal :fee,   precision: 12, scale: 2, null: false, default: 0
      t.decimal :net,   precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
