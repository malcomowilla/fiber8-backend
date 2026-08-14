# frozen_string_literal: true

# Adjust `subscribed` to match however your other channels resolve the
# current tenant (via ApplicationCable::Connection.identified_by, or via
# a subdomain param passed on subscribe — both patterns shown below).
class NetworkMapChannel < ApplicationCable::Channel
  def subscribed
    account = resolve_account
    reject and return unless account

    stream_from "network_map_#{account.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  # Call this from models' after_commit callbacks.
  # kind: 'pop' | 'device' | 'connection'
  # node: the as_map_json payload
  # destroyed: true when the record was deleted, so the frontend removes it
  def self.broadcast_change(account_id, kind:, node:, destroyed: false)
    return unless account_id

    ActionCable.server.broadcast(
      "network_map_#{account_id}",
      { kind: kind, node: node, destroyed: destroyed }
    )
  end

  private

  def resolve_account
    # Option A: if ApplicationCable::Connection already identifies
    # `current_account` (common if you use it for other channels), prefer that:
    return current_account if respond_to?(:current_account) && current_account.present?

    # Option B: fall back to a subdomain passed explicitly when subscribing
    # from the frontend, e.g. consumer.subscriptions.create({ channel: '...', subdomain })
    Account.find_by(subdomain: params[:subdomain])
  end
end