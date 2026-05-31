class AddLastBilledToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :last_billed_at, :datetime
  end
end
