# frozen_string_literal: true

class NetworkConnection < ApplicationRecord
  acts_as_tenant :account

  belongs_to :source, polymorphic: true # Pop or NetworkDevice
  belongs_to :target, polymorphic: true # Pop or NetworkDevice

  validates :category, presence: true

  after_commit :broadcast_map_update

  def as_map_json
    {
      id: id.to_s,
      sourceKind: kind_for(source_type),
      sourceId: source_id.to_s,
      targetKind: kind_for(target_type),
      targetId: target_id.to_s,
      category: category,
      cableType: cable_type,
      label: label,
      bandwidthMbps: bandwidth_mbps,
      distanceM: distance_m,
      status: status,
      path: path,
    }
  end

  private

  def kind_for(type_string)
    type_string == 'Pop' ? 'pop' : 'device'
  end

  def broadcast_map_update
    NetworkMapChannel.broadcast_change(account_id, kind: 'connection', node: as_map_json, destroyed: destroyed?)
  end
end