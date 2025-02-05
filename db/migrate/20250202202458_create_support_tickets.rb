class CreateSupportTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :support_tickets do |t|
      t.string :issue_description
      t.string :status
      t.string :priority
      t.string :agent
      t.string :ticket_number
      t.string :customer
      t.string :name
      t.string :email
      t.string :phone_number
      t.datetime :date_created
      t.string :ticket_category
      t.datetime :date_closed
      t.string :agent_review
      t.string :agent_response
      t.integer :account_id
      t.datetime :date_of_creation

      t.timestamps
    end
  end
end
