json.extract! support_ticket, :id, :issue_description, :status, :priority, :agent, :ticket_number, :customer, :name, :email, :phone_number, :date_created, :ticket_category, :sequence_number, :date_closed, :agent_review, :agent_response, :agent_response, :account_id, :date_of_creation, :created_at, :updated_at
json.url support_ticket_url(support_ticket, format: :json)
