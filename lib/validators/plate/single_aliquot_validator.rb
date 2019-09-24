module Validators
  module Plate
    class SingleAliquotValidator < ActiveModel::Validator
      def validate(record)
        aliquot_types = record.wells.map{|w| w.facts.with_predicate('aliquotType').map(&:object)}
        if (aliquot_types.flatten.uniq.count > 1)
          errors.add(:aliquot_type, 'More than one aliquot type in the same rack')
        end
      end
    end
  end
end
