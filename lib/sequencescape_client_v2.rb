require 'faraday'

module SequencescapeClientV2
  class SequencescapeClientV2::Model < JsonApiClient::Resource # rubocop:todo Style/Documentation
    # Indicates if the asset should be synced back with the remove
    class_attribute :sync

    # set the api base url in an abstract base class
    self.site = "#{Rails.configuration.ss_api_v2_uri}/api/v2/"
    self.sync = false
  end

  class SequencescapeClientV2::Asset < SequencescapeClientV2::Model
  end

  class SequencescapeClientV2::Labware < SequencescapeClientV2::Model # rubocop:todo Style/Documentation
    # The plural of labware is labware
    def self.table_name
      'labware'
    end

    has_many :receptacles

    def sync?
      %w[plates tube_racks].include? type
    end

    def wells
      type == 'plates' ? receptacles : []
    end

    def aliquots
      type == 'tubes' ? receptacles.flat_map(&:aliquots) : []
    end

    def racked_tubes
      if type == 'tube_racks'
        SequencescapeClientV2::TubeRack
          .includes('racked_tubes.tube.aliquots.sample.sample_metadata,racked_tubes.tube.aliquots.study')
          .find(id)
          .first
          .racked_tubes
      else
        []
      end
    end
  end

  class SequencescapeClientV2::Plate < SequencescapeClientV2::Model # rubocop:todo Style/Documentation
    has_many :wells
    has_many :studies, through: :well
    has_many :samples, through: :well
    has_one :purpose

    self.sync = true
  end

  # Api V2 TubeRack from Sequencescape
  class SequencescapeClientV2::TubeRack < SequencescapeClientV2::Model
    has_many :racked_tubes
    has_one :purpose
  end

  # Api V2 Purpose from Sequencescape
  class SequencescapeClientV2::Purpose < SequencescapeClientV2::Model
  end

  # Api V2 Receptacle from Sequencescape
  class SequencescapeClientV2::Receptacle < SequencescapeClientV2::Model
  end

  # Api V2 Well from Sequencescape
  class SequencescapeClientV2::Well < SequencescapeClientV2::Model
    has_many :aliquots
  end

  # Api V2 Tube from Sequencescape
  class SequencescapeClientV2::Tube < SequencescapeClientV2::Model
    has_many :aliquots
  end

  # Api V2 RackedTube from Sequencescape
  class SequencescapeClientV2::RackedTube < SequencescapeClientV2::Model
    has_one :tube
    has_one :tube_rack
  end

  # Api V2 Aliquot from Sequencescape
  class SequencescapeClientV2::Aliquot < SequencescapeClientV2::Model
    belongs_to :asset
    has_one :study
    has_one :sample
  end

  # Api V2 TubeRack from Sequencescape
  class SequencescapeClientV2::Study < SequencescapeClientV2::Model
    has_many :samples
  end

  # Api V2 Sample from Sequencescape
  class SequencescapeClientV2::Sample < SequencescapeClientV2::Model
    has_many :studies
    has_one :sample_metadata
  end

  # Api V2 SampleMetadatum from Sequencescape
  class SequencescapeClientV2::SampleMetadatum < SequencescapeClientV2::Model
    belongs_to :sample
  end
end
