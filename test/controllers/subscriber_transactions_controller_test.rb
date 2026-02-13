require "test_helper"

class SubscriberTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber_transaction = subscriber_transactions(:one)
  end

  test "should get index" do
    get subscriber_transactions_url
    assert_response :success
  end

  test "should get new" do
    get new_subscriber_transaction_url
    assert_response :success
  end

  test "should create subscriber_transaction" do
    assert_difference("SubscriberTransaction.count") do
      post subscriber_transactions_url, params: { subscriber_transaction: { account_id: @subscriber_transaction.account_id, credit: @subscriber_transaction.credit, date: @subscriber_transaction.date, debit: @subscriber_transaction.debit, description: @subscriber_transaction.description, title: @subscriber_transaction.title, type: @subscriber_transaction.type } }
    end

    assert_redirected_to subscriber_transaction_url(SubscriberTransaction.last)
  end

  test "should show subscriber_transaction" do
    get subscriber_transaction_url(@subscriber_transaction)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscriber_transaction_url(@subscriber_transaction)
    assert_response :success
  end

  test "should update subscriber_transaction" do
    patch subscriber_transaction_url(@subscriber_transaction), params: { subscriber_transaction: { account_id: @subscriber_transaction.account_id, credit: @subscriber_transaction.credit, date: @subscriber_transaction.date, debit: @subscriber_transaction.debit, description: @subscriber_transaction.description, title: @subscriber_transaction.title, type: @subscriber_transaction.type } }
    assert_redirected_to subscriber_transaction_url(@subscriber_transaction)
  end

  test "should destroy subscriber_transaction" do
    assert_difference("SubscriberTransaction.count", -1) do
      delete subscriber_transaction_url(@subscriber_transaction)
    end

    assert_redirected_to subscriber_transactions_url
  end
end
