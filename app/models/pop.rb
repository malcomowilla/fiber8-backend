# frozen_string_literal: true

class Pop < ApplicationRecord
  acts_as_tenant :account

  belongs_to :router, optional: true
  has_many :network_devices, dependent: :nullify
  has_many :outgoing_connections, as: :source, class_name: 'NetworkConnection', dependent: :destroy
  has_many :incoming_connections, as: :target, class_name: 'NetworkConnection', dependent: :destroy

  validates :name, presence: true
  validates :lat, :lng, presence: true

  after_commit :broadcast_map_update

  def as_map_json
    {
      id: id.to_s,
      name: name,
      lat: lat,
      lng: lng,
      address: address,
      routerId: router_id&.to_s,
      status: status,
      description: description,
    }
  end

  private

  def broadcast_map_update
    NetworkMapChannel.broadcast_change(account_id, kind: 'pop', node: as_map_json, destroyed: destroyed?)
  end
end