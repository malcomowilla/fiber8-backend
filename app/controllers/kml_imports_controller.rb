# frozen_string_literal: true

class KmlImportsController < ApplicationController
  include NetworkMapTenantScoped

  # POST /network_map/kml_import  (multipart/form-data, field name "file")
  def create
    authorize! :create, NetworkDevice
    file = params[:file]
    return render json: { error: 'No file provided' }, status: :unprocessable_entity unless file

    result = KmlImporterService.new(account: @account, file: file).call

    render json: {
      createdDevices: result[:devices].map(&:as_map_json),
      skipped: result[:skipped],
      unmappedLines: result[:raw_lines], # LineString placemarks (fiber routes) — see note below
    }, status: :created
  rescue KmlImporterService::InvalidFileError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

# NOTE ON FIBER ROUTES: KML LineStrings (e.g. a drawn ADSS run in Google
# Earth) don't carry which two devices they connect — that's a modeling
# decision only a human can make. This importer creates point placemarks
# (poles, cabinets, closures, OLTs, etc.) as NetworkDevice records
# automatically, but returns line placemarks as `unmappedLines` so you can
# review them and manually draw the Link on the map afterward, snapped to
# the real devices. Auto-guessing nearest-endpoint devices was considered
# and rejected — it would silently create wrong topology on a messy KML.