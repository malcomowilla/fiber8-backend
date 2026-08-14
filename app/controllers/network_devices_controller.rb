# frozen_string_literal: true

class NetworkDevicesController < ApplicationController
  include NetworkMapTenantScoped

  before_action :set_device, only: %i[update destroy]

  def create
    authorize! :create, NetworkDevice
    device = NetworkDevice.new(device_params.merge(account: @account))
    if device.save
      render json: device.as_map_json, status: :created
    else
      render json: { errors: device.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @device
    if @device.update(device_params)
      render json: @device.as_map_json
    else
      render json: { errors: @device.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @device
    @device.destroy
    head :no_content
  end

  private

  def set_device
    @device = NetworkDevice.find(params[:id])
  end

  def device_params
    raw = params.permit(:type, :name, :identifier, :lat, :lng, :address, :routerId, :status, :description, :parentId).to_h
    {
      device_type: raw['type'],
      name: raw['name'],
      identifier: raw['identifier'],
      lat: raw['lat'],
      lng: raw['lng'],
      address: raw['address'],
      router_id: raw['routerId'].presence,
      pop_id: raw['parentId'].presence,
      status: raw['status'],
      description: raw['description'],
    }.compact
  end
end