module Validators
  module Plate
    class DuplicatedTubesValidator < ActiveModel::Validator
      def validate(record)
        duplicated = record.wells.select do |element|
          element.facts.with_predicate('location').count > 1
        end.uniq
        unless duplicated.empty?
          duplicated.each do |duplicate_tube|
            errors.add("#{duplicated_tube.barcode}","The tube #{duplicated_tube.barcode} is duplicated in the layout")
          end
        end
      end
    end
  end
end
