module Actions
  module TubeTransfer # rubocop:todo Style/Documentation
    def transfer_tubes(asset, modified_asset)
      FactChanges.new.tap do |updates|
        %w[study_uuid sample_uuid sanger_sample_name supplier_sample_name sample_common_name].each do |field|
          if asset.has_predicate?(field)
            updates.add(modified_asset, field, asset.facts.with_predicate(field).first.object)
          end
        end
        if asset.has_predicate?('sample_tube')
          updates.add(modified_asset, 'sample_tube', asset.facts.with_predicate('sample_tube').first.object_asset)
        end
        if asset.has_predicate?('study_name')
          updates.add(modified_asset, 'study_name', asset.facts.with_predicate('study_name').first.object)
        end

        asset
          .facts
          .with_predicate('sanger_sample_id')
          .each do |aliquot_fact|
            updates.add(modified_asset, 'sanger_sample_id', aliquot_fact.object)
            updates.add(modified_asset, 'sample_id', aliquot_fact.object)
          end
        unless modified_asset.has_predicate?('aliquotType')
          asset
            .facts
            .with_predicate('aliquotType')
            .each { |aliquot_fact| updates.add(modified_asset, 'aliquotType', aliquot_fact.object) }
        end
        if asset.has_predicate?('volume') && asset.has_predicate?('transferVolume')
          transferredVolume = asset.facts.with_predicate('transferVolume').first.object
          actualVolume = asset.facts.with_predicate('volume').first.object
          nextVolume = (actualVolume.to_i - transferredVolume.to_i)
          if nextVolume < 0
            transferredVolume = transferredVolume.to_i + nextVolume.to_i
            actualVolume = 0
          end
          updates.add(modified_asset, 'transferVolume', transferredVolume)
          updates.remove_where(asset, 'volume', actualVolume)
          updates.add(asset, 'volume', nextVolume)
          updates.add(modified_asset, 'volume', transferredVolume)

          updates.add(asset, 'is', 'Empty') if nextVolume == 0
        end
      end
    end
  end
end
