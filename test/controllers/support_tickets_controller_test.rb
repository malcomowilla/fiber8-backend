require "test_helper"

class SupportTicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @support_ticket = support_tickets(:one)
  end

  test "should get index" do
    get support_tickets_url
    assert_response :success
  end

  test "should get new" do
    get new_support_ticket_url
    assert_response :success
  end

  test "should create support_ticket" do
    assert_difference("SupportTicket.count") do
      post support_tickets_url, params: { support_ticket: { account_id: @support_ticket.account_id, agent: @support_ticket.agent, agent_response: @support_ticket.agent_response, agent_review: @support_ticket.agent_review, customer: @support_ticket.customer, date_closed: @support_ticket.date_closed, date_created: @support_ticket.date_created, date_of_creation: @support_ticket.date_of_creation, email: @support_ticket.email, issue_description: @support_ticket.issue_description, name: @support_ticket.name, phone_number: @support_ticket.phone_number, priority: @support_ticket.priority, sequence_number: @support_ticket.sequence_number, status: @support_ticket.status, ticket_category: @support_ticket.ticket_category, ticket_number: @support_ticket.ticket_number } }
    end

    assert_redirected_to support_ticket_url(SupportTicket.last)
  end

  test "should show support_ticket" do
    get support_ticket_url(@support_ticket)
    assert_response :success
  end

  test "should get edit" do
    get edit_support_ticket_url(@support_ticket)
    assert_response :success
  end

  test "should update support_ticket" do
    patch support_ticket_url(@support_ticket), params: { support_ticket: { account_id: @support_ticket.account_id, agent: @support_ticket.agent, agent_response: @support_ticket.agent_response, agent_review: @support_ticket.agent_review, customer: @support_ticket.customer, date_closed: @support_ticket.date_closed, date_created: @support_ticket.date_created, date_of_creation: @support_ticket.date_of_creation, email: @support_ticket.email, issue_description: @support_ticket.issue_description, name: @support_ticket.name, phone_number: @support_ticket.phone_number, priority: @support_ticket.priority, sequence_number: @support_ticket.sequence_number, status: @support_ticket.status, ticket_category: @support_ticket.ticket_category, ticket_number: @support_ticket.ticket_number } }
    assert_redirected_to support_ticket_url(@support_ticket)
  end

  test "should destroy support_ticket" do
    assert_difference("SupportTicket.count", -1) do
      delete support_ticket_url(@support_ticket)
    end

    assert_redirected_to support_tickets_url
  end
end
