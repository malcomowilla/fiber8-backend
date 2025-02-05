require "application_system_test_case"

class SupportTicketsTest < ApplicationSystemTestCase
  setup do
    @support_ticket = support_tickets(:one)
  end

  test "visiting the index" do
    visit support_tickets_url
    assert_selector "h1", text: "Support tickets"
  end

  test "should create support ticket" do
    visit support_tickets_url
    click_on "New support ticket"

    fill_in "Account", with: @support_ticket.account_id
    fill_in "Agent", with: @support_ticket.agent
    fill_in "Agent response", with: @support_ticket.agent_response
    fill_in "Agent review", with: @support_ticket.agent_review
    fill_in "Customer", with: @support_ticket.customer
    fill_in "Date closed", with: @support_ticket.date_closed
    fill_in "Date created", with: @support_ticket.date_created
    fill_in "Date of creation", with: @support_ticket.date_of_creation
    fill_in "Email", with: @support_ticket.email
    fill_in "Issue description", with: @support_ticket.issue_description
    fill_in "Name", with: @support_ticket.name
    fill_in "Phone number", with: @support_ticket.phone_number
    fill_in "Priority", with: @support_ticket.priority
    fill_in "Sequence number", with: @support_ticket.sequence_number
    fill_in "Status", with: @support_ticket.status
    fill_in "Ticket category", with: @support_ticket.ticket_category
    fill_in "Ticket number", with: @support_ticket.ticket_number
    click_on "Create Support ticket"

    assert_text "Support ticket was successfully created"
    click_on "Back"
  end

  test "should update Support ticket" do
    visit support_ticket_url(@support_ticket)
    click_on "Edit this support ticket", match: :first

    fill_in "Account", with: @support_ticket.account_id
    fill_in "Agent", with: @support_ticket.agent
    fill_in "Agent response", with: @support_ticket.agent_response
    fill_in "Agent review", with: @support_ticket.agent_review
    fill_in "Customer", with: @support_ticket.customer
    fill_in "Date closed", with: @support_ticket.date_closed
    fill_in "Date created", with: @support_ticket.date_created
    fill_in "Date of creation", with: @support_ticket.date_of_creation
    fill_in "Email", with: @support_ticket.email
    fill_in "Issue description", with: @support_ticket.issue_description
    fill_in "Name", with: @support_ticket.name
    fill_in "Phone number", with: @support_ticket.phone_number
    fill_in "Priority", with: @support_ticket.priority
    fill_in "Sequence number", with: @support_ticket.sequence_number
    fill_in "Status", with: @support_ticket.status
    fill_in "Ticket category", with: @support_ticket.ticket_category
    fill_in "Ticket number", with: @support_ticket.ticket_number
    click_on "Update Support ticket"

    assert_text "Support ticket was successfully updated"
    click_on "Back"
  end

  test "should destroy Support ticket" do
    visit support_ticket_url(@support_ticket)
    click_on "Destroy this support ticket", match: :first

    assert_text "Support ticket was successfully destroyed"
  end
end
