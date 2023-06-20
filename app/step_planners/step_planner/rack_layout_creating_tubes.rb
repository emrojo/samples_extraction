# frozen_string_literal: true

require 'actions/racking'

module StepPlanner
  # Allows the upload of a tube rack layout to register the tubes
  class RackLayoutCreatingTubes
    attr_reader :asset_group

    include Actions::Racking

    def initialize(asset_group_id, _step_id)
      @asset_group = AssetGroup.find(asset_group_id)
    end

    def assets_compatible_with_step_type
      asset_group.uploaded_files
    end

    def process
      FactChanges.new.tap do |updates|
        if assets_compatible_with_step_type.any?
          updates.merge(rack_layout_creating_tubes)
          updates.remove_assets([[asset_group.uploaded_files.first.asset.uuid]])
        end
      end
    end

    def updates
      ActiveRecord::Base.transaction { process }
    rescue InvalidDataParams => e
      { set_errors: e.errors }
    rescue StandardError => e
      { set_errors: ["Unknown error while applying barcodes: #{e.message}, #{e.backtrace}"] }
    end
  end
end
