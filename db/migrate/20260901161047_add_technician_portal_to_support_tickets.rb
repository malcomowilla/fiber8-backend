class AddTechnicianPortalToSupportTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :support_tickets, :access_token, :string
    add_column :support_tickets, :technician_updated_at, :datetime
    add_index :support_tickets, :access_token, unique: true

    create_table :ticket_updates do |t|
      t.references :support_ticket, null: false, foreign_key: true
      t.string :status
      t.text :remark
      t.string :updated_by
      t.string :source, default: 'admin' # 'admin' or 'technician'
      t.timestamps
    end
  end
end
