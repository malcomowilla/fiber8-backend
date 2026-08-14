# frozen_string_literal: true

class NetworkConnectionsController < ApplicationController
  include NetworkMapTenantScoped

  before_action :set_connection, only: %i[update destroy]

  KIND_MODEL = { 'pop' => 'Pop', 'device' => 'NetworkDevice' }.freeze

  def create
    authorize! :create, NetworkConnection
    conn = NetworkConnection.new(connection_attrs(creating: true).merge(account: @account))
    if conn.save
      render json: conn.as_map_json, status: :created
    else
      render json: { errors: conn.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @connection
    if @connection.update(connection_attrs(creating: false))
      render json: @connection.as_map_json
    else
      render json: { errors: @connection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @connection
    @connection.destroy
    head :no_content
  end

  private

  def set_connection
    @connection = NetworkConnection.find(params[:id])
  end

  def connection_attrs(creating:)
    raw = params.permit(
      :category, :cableType, :label, :bandwidthMbps, :distanceM, :status,
      :sourceKind, :sourceId, :targetKind, :targetId
    ).to_h

    attrs = {
      category: raw['category'],
      cable_type: raw['cableType'],
      label: raw['label'],
      bandwidth_mbps: raw['bandwidthMbps'].presence,
      distance_m: raw['distanceM'].presence,
      status: raw['status'],
    }.compact

    if raw['targetKind'] && raw['targetId']
      attrs[:target_type] = KIND_MODEL.fetch(raw['targetKind'])
      attrs[:target_id] = raw['targetId']
    end

    # Source is fixed at creation time (the marker the admin clicked first)
    # and never changes on update, matching the frontend's ConnectionModal.
    if creating && raw['sourceKind'] && raw['sourceId']
      attrs[:source_type] = KIND_MODEL.fetch(raw['sourceKind'])
      attrs[:source_id] = raw['sourceId']
    end

    attrs
  end
end