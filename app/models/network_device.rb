# frozen_string_literal: true

class NetworkDevice < ApplicationRecord
  acts_as_tenant :account

  belongs_to :pop, optional: true
  belongs_to :router, optional: true
  has_many :outgoing_connections, as: :source, class_name: 'NetworkConnection', dependent: :destroy
  has_many :incoming_connections, as: :target, class_name: 'NetworkConnection', dependent: :destroy

  validates :name, :device_type, presence: true
  validates :lat, :lng, presence: true

  after_commit :broadcast_map_update

  def as_map_json
    {
      id: id.to_s,
      type: device_type,
      name: name,
      identifier: identifier,
      lat: lat,
      lng: lng,
      address: address,
      routerId: router_id&.to_s,
      parentId: pop_id&.to_s,
      status: status,
      description: description,
      source: source,
    }
  end

  private

  def broadcast_map_update
    NetworkMapChannel.broadcast_change(account_id, kind: 'device', node: as_map_json, destroyed: destroyed?)
  end
end