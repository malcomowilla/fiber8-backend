require "test_helper"

class SubscriberInvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber_invoice = subscriber_invoices(:one)
  end

  test "should get index" do
    get subscriber_invoices_url
    assert_response :success
  end

  test "should get new" do
    get new_subscriber_invoice_url
    assert_response :success
  end

  test "should create subscriber_invoice" do
    assert_difference("SubscriberInvoice.count") do
      post subscriber_invoices_url, params: { subscriber_invoice: { account_id: @subscriber_invoice.account_id, amount: @subscriber_invoice.amount, description: @subscriber_invoice.description, due_date: @subscriber_invoice.due_date, invoice_date: @subscriber_invoice.invoice_date, invoice_number: @subscriber_invoice.invoice_number, item: @subscriber_invoice.item, quantity: @subscriber_invoice.quantity, status: @subscriber_invoice.status } }
    end

    assert_redirected_to subscriber_invoice_url(SubscriberInvoice.last)
  end

  test "should show subscriber_invoice" do
    get subscriber_invoice_url(@subscriber_invoice)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscriber_invoice_url(@subscriber_invoice)
    assert_response :success
  end

  test "should update subscriber_invoice" do
    patch subscriber_invoice_url(@subscriber_invoice), params: { subscriber_invoice: { account_id: @subscriber_invoice.account_id, amount: @subscriber_invoice.amount, description: @subscriber_invoice.description, due_date: @subscriber_invoice.due_date, invoice_date: @subscriber_invoice.invoice_date, invoice_number: @subscriber_invoice.invoice_number, item: @subscriber_invoice.item, quantity: @subscriber_invoice.quantity, status: @subscriber_invoice.status } }
    assert_redirected_to subscriber_invoice_url(@subscriber_invoice)
  end

  test "should destroy subscriber_invoice" do
    assert_difference("SubscriberInvoice.count", -1) do
      delete subscriber_invoice_url(@subscriber_invoice)
    end

    assert_redirected_to subscriber_invoices_url
  end
end
