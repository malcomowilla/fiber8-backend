class CollectorBuildingsController < ApplicationController
  include CollectorAuth

  # POST /api/collector/buildings
  def create
    building = CollectorBuilding.new(params.permit(:name, :area, :units))
    if building.save
      render json: building.as_row, status: :created
    else
      render json: { errors: building.errors.full_messages }, status: :unprocessable_entity
    end
  end
end