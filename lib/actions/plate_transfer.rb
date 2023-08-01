module Actions
  module PlateTransfer # rubocop:todo Style/Documentation
    def self.to_sequencescape_location(location)
      loc = location.match(/(\w)(0*)(\d*)/)
      loc[1] + loc[3]
    end

    def self.ignored_predicates_for_existing_well
      %w[a parent pushedTo]
    end

    def self.ignored_predicates_for_new_well
      ['pushedTo']
    end

    def self.validate_plate_is_compatible_with_aliquot(updates, plate, aliquotType)
      aliquots = plate.facts.with_predicate('aliquotType').map(&:object).uniq
      return true if aliquots.empty?

      if (aliquots.size != 1) || (aliquots.first != aliquotType)
        updates.set_errors(
          ["The plate #{plate.barcode} contains aliquot #{aliquots.first} which is not compatible with #{aliquotType}"]
        )
        return false
      end
      true
    end

    def self.validate_tube_is_compatible_with_aliquot(updates, tube, aliquotType)
      aliquots = tube.facts.with_predicate('aliquotType').map(&:object).uniq
      return true if aliquots.empty?

      if (aliquots.size != 1) || (aliquots.first != aliquotType)
        updates.set_errors(
          ["The tube #{tube.barcode} contains aliquot #{aliquots.first} which is not compatible with #{aliquotType}"]
        )
        return false
      end
      true
    end

    def self.transfer_by_location(plate, destination, updates = nil)
      aliquot = plate.facts.where(predicate: 'aliquotType').first
      updates ||= FactChanges.new
      updates.tap do |updates|
        if aliquot
          return updates unless validate_plate_is_compatible_with_aliquot(updates, destination, aliquot.object)
        end
        updates.add(destination, 'aliquotType', aliquot.object) if aliquot
        value =
          plate
            .facts
            .with_predicate('contains')
            .reduce({}) do |memo, f|
              location = to_sequencescape_location(f.object_asset.facts.with_predicate('location').first.object)
              memo[location] = [] unless memo[location]
              memo[location].push(f.object_asset)
              memo
            end
        value =
          destination
            .facts
            .with_predicate('contains')
            .reduce(value) do |memo, f|
              location = to_sequencescape_location(f.object_asset.facts.with_predicate('location').first.object)
              memo[location] = [] unless memo[location]
              memo[location].push(f.object_asset)
              memo
            end
        value.each do |_location, assets|
          asset1, asset2 = assets
          if asset2
            if aliquot
              return updates unless validate_tube_is_compatible_with_aliquot(updates, asset2, aliquot.object)
            end
            updates.add(asset2, 'aliquotType', aliquot.object) if aliquot && !asset2.has_predicate?('aliquotType')
            asset1.facts.each do |fact|
              unless ignored_predicates_for_existing_well.include?(fact.predicate)
                updates.add(asset2, fact.predicate, fact.object_value)
              end
            end
          end
        end
      end
    end

    def self.transfer_with_asset_creation(plate, destination, updates = nil)
      aliquot_value = updates.values_for_predicate(destination, 'aliquotType').first
      updates ||= FactChanges.new
      updates.tap do |updates|
        contains_facts =
          plate
            .facts
            .with_predicate('contains')
            .map do |contain_fact|
              source_well = contain_fact.object_asset
              destination_well = Asset.new
              updates.create_assets([destination_well])
              source_well.facts.each do |fact|
                unless ignored_predicates_for_new_well.include?(fact.predicate)
                  updates.add(destination_well, fact.predicate, fact.object_value, literal: fact.literal)
                end
              end
              updates.add(destination_well, 'barcodeType', 'NoBarcode')
              if aliquot_value && !source_well.has_predicate?('aliquotType')
                updates.add(destination_well, 'aliquotType', aliquot_value)
              end
              updates.add(destination, 'contains', destination_well)
            end
      end
    end

    #
    # plate: Asset
    # destimation: Asset or String representing a uuid or a wildcard
    def self.transfer_plates(plate, destination, updates = nil)
      updates ||= FactChanges.new
      updates.tap do |updates|
        if destination.kind_of?(Asset) && (destination.has_wells?)
          transfer_by_location(plate, destination, updates)
        else
          transfer_with_asset_creation(plate, destination, updates)
        end
      end
    end
  end
end
