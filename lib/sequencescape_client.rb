# frozen_string_literal: true

require 'sequencescape-api'
require 'sequencescape'

require 'sequencescape_client_v2'

class SequencescapeClient
  SELECT_FOR_IMPORT = 'uuid,labware_barcode,receptacles'
  @purposes = nil

  def self.api_connection_options
    {
      :namespace => 'SamplesExtraction',
      :url => Rails.configuration.ss_uri,
      :authorisation => Rails.configuration.ss_authorisation,
      :read_timeout => 60
    }
  end

  def self.client
    @client ||= Sequencescape::Api.new(self.api_connection_options)
  end

  def self.version_1_find_by_uuid(uuid, type = :plate)
    client.send(type).find(uuid)
  rescue Sequencescape::Api::ResourceNotFound => exception
    return nil
  end

  # below creates a record in the 'extraction_attributes' table in Sequencescape
  # this, in turn, triggers creation of aliquots against the plate
  def self.update_extraction_attributes(instance, attrs, username = 'test')
    instance.extraction_attributes.create!(:attributes_update => attrs, :created_by => username)
  end

  def self.purpose_by_name(name)
    client.plate_purpose.all.find { |p| p.name === name }
  end

  def self.create_plate(purpose_name)
    purpose = purpose_by_name(purpose_name) || purpose_by_name('Stock Plate')
    purpose.plates.create!({})
  end

  def self.get_remote_asset(barcode)
    find_by(barcode: barcode)
  end

  def self.find_by_uuid(uuid)
    find_by(uuid: uuid)
  end

  def self.labware(conditions)
    SequencescapeClientV2::Labware
      .includes('receptacles.aliquots.sample.sample_metadata')
      .select(
        tubes: SELECT_FOR_IMPORT,
        plates: SELECT_FOR_IMPORT,
        tube_racks: 'uuid,labware_barcode',
        samples: 'sanger_sample_id,uuid,name',
        sample_metadata: 'supplier_name,sample_common_name'
      ).where(conditions)
  end

  # TODO: In most cases we should know what type of record we're looking up.
  def self.find_by(search_conditions)
    [
      SequencescapeClientV2::Plate.includes('wells.aliquots.sample.sample_metadata'),
      SequencescapeClientV2::Tube.includes('aliquots.sample.sample_metadata'),
      SequencescapeClientV2::Well.includes('aliquots.sample.sample_metadata'),
      SequencescapeClientV2::TubeRack.includes('racked_tubes.tube.aliquots.sample.sample_metadata')
    ].each do |klass|
      begin
        search = klass.where(search_conditions).first
        return search if search
      rescue JsonApiClient::Errors::ClientError => e
        # Ignore filter error
      end
    end
    nil
  end
end
