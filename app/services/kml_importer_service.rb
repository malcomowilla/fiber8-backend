# frozen_string_literal: true

require 'nokogiri'
require 'zip' # gem 'rubyzip' — add to Gemfile if not already present

# Parses a .kml or .kmz file (as exported by "Save Place As..." in Google
# Earth / Google Earth Pro) into NetworkDevice records on the current
# tenant. Placemarks are matched to a device type by the KML Folder name
# they sit in (e.g. a folder called "Cabinets" -> device_type "cabinet"),
# falling back to "ont" for anything unrecognized so nothing is silently
# dropped.
class KmlImporterService
  class InvalidFileError < StandardError; end

  FOLDER_TO_DEVICE_TYPE = {
    'pole' => 'pole', 'poles' => 'pole',
    'cabinet' => 'cabinet', 'cabinets' => 'cabinet',
    'closure' => 'closure', 'closures' => 'closure',
    'tower' => 'ap', 'towers' => 'ap', 'mast' => 'ap', 'masts' => 'ap',
    'olt' => 'olt', 'olts' => 'olt',
    'switch' => 'switch', 'switches' => 'switch',
    'fat' => 'fat', 'fats' => 'fat',
    'splitter' => 'splitter', 'splitters' => 'splitter',
    'ont' => 'ont', 'onts' => 'ont',
    'router' => 'bridge', 'routers' => 'bridge', 'bridge' => 'bridge',
    'hotspot' => 'hotspot', 'hotspots' => 'hotspot',
  }.freeze

  def initialize(account:, file:)
    @account = account
    @file = file
  end

  def call
    doc = Nokogiri::XML(extract_kml_xml)
    doc.remove_namespaces! # KML namespaces vary by Earth version; ignore them for xpath simplicity

    devices = []
    skipped = []
    raw_lines = []

    doc.xpath('//Placemark').each do |placemark|
      name = placemark.at_xpath('name')&.text&.strip.presence || 'Imported Asset'
      description = strip_html(placemark.at_xpath('description')&.text)
      folder = placemark.at_xpath('ancestor::Folder/name')&.text&.strip&.downcase

      if (point = placemark.at_xpath('.//Point/coordinates'))
        lng, lat, = point.text.strip.split(',').map(&:to_f)
        device_type = FOLDER_TO_DEVICE_TYPE[folder] || 'ont'

        device = NetworkDevice.new(
          account: @account,
          name: name,
          description: description,
          device_type: device_type,
          lat: lat,
          lng: lng,
          status: 'unknown',
          source: 'kml_import'
        )

        if device.save
          devices << device
        else
          skipped << { name: name, errors: device.errors.full_messages }
        end
      elsif (line = placemark.at_xpath('.//LineString/coordinates'))
        coords = line.text.strip.split(/\s+/).map { |c| c.split(',').map(&:to_f) }
        raw_lines << { name: name, description: description, path: coords.map { |lngv, latv| [latv, lngv] } }
      else
        skipped << { name: name, errors: ['No Point or LineString geometry found'] }
      end
    end

    { devices: devices, skipped: skipped, raw_lines: raw_lines }
  end

  private

  def extract_kml_xml
    filename = @file.original_filename.to_s.downcase

    if filename.end_with?('.kmz')
      Zip::File.open(@file.tempfile.path) do |zip|
        entry = zip.glob('*.kml').first || zip.glob('**/*.kml').first
        raise InvalidFileError, 'KMZ file does not contain a .kml document' unless entry

        return entry.get_input_stream.read
      end
    elsif filename.end_with?('.kml')
      @file.read
    else
      raise InvalidFileError, 'Only .kml or .kmz files are supported'
    end
  end

  def strip_html(text)
    return nil if text.blank?

    ActionController::Base.helpers.strip_tags(text).strip.presence
  end
end