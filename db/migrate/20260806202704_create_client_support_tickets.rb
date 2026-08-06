class CreateClientSupportTickets < ActiveRecord::Migration[7.2]
   def change
    create_table :client_support_tickets do |t|
      t.string :subject, null: false
      t.text :description, null: false
      t.string :category, default: 'system' # system, payment, network, other
      t.string :priority, default: 'medium' # low, medium, high, urgent
      t.string :status, default: 'open'     # open, in_progress, resolved, closed
      t.string :raised_by_name
      t.string :raised_by_email
      t.string :raised_by_phone
      t.references :account, null: false, index: true
      t.datetime :resolved_at
      t.text :admin_notes

      t.timestamps
    end

    add_index :client_support_tickets, :status
    add_index :client_support_tickets, :priority
  end
end
