class CreatePop < ActiveRecord::Migration[7.2]
  def change
    unless table_exists?(:pops)
      create_table :pops do |t|
        t.timestamps
      end
    end

    add_reference :pops, :account, foreign_key: true, index: true unless column_exists?(:pops, :account_id)
    add_column :pops, :name, :string unless column_exists?(:pops, :name)
    add_column :pops, :lat, :float unless column_exists?(:pops, :lat)
    add_column :pops, :lng, :float unless column_exists?(:pops, :lng)
    add_column :pops, :address, :string unless column_exists?(:pops, :address)
    add_column :pops, :router_id, :bigint unless column_exists?(:pops, :router_id)
    add_column :pops, :status, :string, default: 'active' unless column_exists?(:pops, :status)
    add_column :pops, :description, :text unless column_exists?(:pops, :description)

    add_index :pops, :account_id unless index_exists?(:pops, :account_id)
    add_index :pops, :router_id unless index_exists?(:pops, :router_id)
  end
end
