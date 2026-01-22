require "application_system_test_case"

class SubscriberInvoicesTest < ApplicationSystemTestCase
  setup do
    @subscriber_invoice = subscriber_invoices(:one)
  end

  test "visiting the index" do
    visit subscriber_invoices_url
    assert_selector "h1", text: "Subscriber invoices"
  end

  test "should create subscriber invoice" do
    visit subscriber_invoices_url
    click_on "New subscriber invoice"

    fill_in "Account", with: @subscriber_invoice.account_id
    fill_in "Amount", with: @subscriber_invoice.amount
    fill_in "Description", with: @subscriber_invoice.description
    fill_in "Due date", with: @subscriber_invoice.due_date
    fill_in "Invoice date", with: @subscriber_invoice.invoice_date
    fill_in "Invoice number", with: @subscriber_invoice.invoice_number
    fill_in "Item", with: @subscriber_invoice.item
    fill_in "Quantity", with: @subscriber_invoice.quantity
    fill_in "Status", with: @subscriber_invoice.status
    click_on "Create Subscriber invoice"

    assert_text "Subscriber invoice was successfully created"
    click_on "Back"
  end

  test "should update Subscriber invoice" do
    visit subscriber_invoice_url(@subscriber_invoice)
    click_on "Edit this subscriber invoice", match: :first

    fill_in "Account", with: @subscriber_invoice.account_id
    fill_in "Amount", with: @subscriber_invoice.amount
    fill_in "Description", with: @subscriber_invoice.description
    fill_in "Due date", with: @subscriber_invoice.due_date.to_s
    fill_in "Invoice date", with: @subscriber_invoice.invoice_date.to_s
    fill_in "Invoice number", with: @subscriber_invoice.invoice_number
    fill_in "Item", with: @subscriber_invoice.item
    fill_in "Quantity", with: @subscriber_invoice.quantity
    fill_in "Status", with: @subscriber_invoice.status
    click_on "Update Subscriber invoice"

    assert_text "Subscriber invoice was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscriber invoice" do
    visit subscriber_invoice_url(@subscriber_invoice)
    click_on "Destroy this subscriber invoice", match: :first

    assert_text "Subscriber invoice was successfully destroyed"
  end
end
