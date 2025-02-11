class CreateTicketSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_settings do |t|
      t.string :prefix
      t.string :minimum_digits
      t.integer :account_id

      t.timestamps
    end
  end
end
