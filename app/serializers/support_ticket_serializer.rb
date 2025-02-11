class SupportTicketSerializer < ActiveModel::Serializer
  attributes :id, :issue_description, :status, :priority, :agent, :ticket_number, :customer,
  :name, :email, :phone_number, :date_created, :ticket_category, :formatted_date_of_creation, :formatted_date_closed,
  :agent_review, :agent_response



def formatted_date_of_creation
 object.date_of_creation.strftime('%Y-%m-%d %I:%M:%S %p') if object.date_of_creation.present?
end



def formatted_date_closed
 object.date_closed.strftime('%Y-%m-%d %I:%M:%S %p') if object.date_closed.present?
end
end
