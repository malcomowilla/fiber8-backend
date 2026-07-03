class CreatePromotionalPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :promotional_plans do |t|
      t.references :hotspot_package, null: false, foreign_key: true

      # Promotion details
      t.string  :name, null: false
      t.string  :badge_text
      t.text    :description

      # Schedule
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.string   :recurrence_type, null: false, default: 'one_time' # one_time | daily_window
      t.time     :daily_start_time
      t.time     :daily_end_time
      t.integer :account_id

      # Discount
      t.string  :discount_type, null: false, default: 'percentage' # percentage | fixed_amount
      t.decimal :discount_value, precision: 10, scale: 2, null: false

      # Stock & priority
      t.integer :max_redemptions
      t.integer :current_redemptions, null: false, default: 0
      t.integer :display_priority, null: false, default: 0

      # Display options
      t.boolean :show_countdown_timer, null: false, default: true
      t.boolean :show_stock_indicator, null: false, default: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :promotional_plans, [:account_id, :active]
    add_index :promotional_plans, [:start_date, :end_date]
  end
end
