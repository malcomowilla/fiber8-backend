require "application_system_test_case"

class SubscriberTransactionsTest < ApplicationSystemTestCase
  setup do
    @subscriber_transaction = subscriber_transactions(:one)
  end

  test "visiting the index" do
    visit subscriber_transactions_url
    assert_selector "h1", text: "Subscriber transactions"
  end

  test "should create subscriber transaction" do
    visit subscriber_transactions_url
    click_on "New subscriber transaction"

    fill_in "Account", with: @subscriber_transaction.account_id
    fill_in "Credit", with: @subscriber_transaction.credit
    fill_in "Date", with: @subscriber_transaction.date
    fill_in "Debit", with: @subscriber_transaction.debit
    fill_in "Description", with: @subscriber_transaction.description
    fill_in "Title", with: @subscriber_transaction.title
    fill_in "Type", with: @subscriber_transaction.type
    click_on "Create Subscriber transaction"

    assert_text "Subscriber transaction was successfully created"
    click_on "Back"
  end

  test "should update Subscriber transaction" do
    visit subscriber_transaction_url(@subscriber_transaction)
    click_on "Edit this subscriber transaction", match: :first

    fill_in "Account", with: @subscriber_transaction.account_id
    fill_in "Credit", with: @subscriber_transaction.credit
    fill_in "Date", with: @subscriber_transaction.date
    fill_in "Debit", with: @subscriber_transaction.debit
    fill_in "Description", with: @subscriber_transaction.description
    fill_in "Title", with: @subscriber_transaction.title
    fill_in "Type", with: @subscriber_transaction.type
    click_on "Update Subscriber transaction"

    assert_text "Subscriber transaction was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscriber transaction" do
    visit subscriber_transaction_url(@subscriber_transaction)
    click_on "Destroy this subscriber transaction", match: :first

    assert_text "Subscriber transaction was successfully destroyed"
  end
end
