# frozen_string_literal: true

class PopsController < ApplicationController
  include NetworkMapTenantScoped

  before_action :set_pop, only: %i[update destroy]

  def create
    authorize! :create, Pop
    pop = Pop.new(pop_params.merge(account: @account))
    if pop.save
      render json: pop.as_map_json, status: :created
    else
      render json: { errors: pop.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize! :update, @pop
    if @pop.update(pop_params)
      render json: @pop.as_map_json
    else
      render json: { errors: @pop.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @pop
    @pop.destroy
    head :no_content
  end

  private

  def set_pop
    @pop = Pop.find(params[:id])
  end

  def pop_params
    raw = params.permit(:name, :lat, :lng, :address, :routerId, :status, :description).to_h
    {
      name: raw['name'],
      lat: raw['lat'],
      lng: raw['lng'],
      address: raw['address'],
      router_id: raw['routerId'].presence,
      status: raw['status'],
      description: raw['description'],
    }.compact
  end
end