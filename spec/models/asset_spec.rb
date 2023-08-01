require 'rails_helper'
RSpec.describe Asset, type: :model do
  context '#class_type' do
    context 'when having several valid types' do
      let(:props) { [create(:fact, predicate: 'a', object: 'Tube'), create(:fact, predicate: 'a', object: 'Well')] }
      let(:asset) { create :asset, facts: props }

      it 'returns the right prioritised class type' do
        expect(asset.class_type).to eq('Tube')
      end
    end
    context 'when not having any valid types' do
      let(:props) do
        [create(:fact, predicate: 'a', object: 'Something'), create(:fact, predicate: 'a', object: 'Another')]
      end
      let(:asset) { create :asset, facts: props }

      it 'returns the first value when not recognised' do
        expect(asset.class_type).to eq('Something')
      end
    end

    context 'when not having anything' do
      let(:props) { [] }
      let(:asset) { create :asset, facts: props }

      it 'returns empty string' do
        expect(asset.class_type).to eq('')
      end
    end
  end
  context '#has_wells?' do
    it 'returns true when it is a plate with wells' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(true)
    end
    it 'returns false when it is an empty plate' do
      plate = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Plate')
      well = create(:asset)
      expect(plate.has_wells?).to eq(false)
    end
    it 'returns false when it is something else' do
      plate = create(:asset)
      something_else = create(:asset)
      plate.facts << create(:fact, predicate: 'a', object: 'Bottle')
      well = create(:asset)
      plate.facts << create(:fact, predicate: 'contains', object_asset: well)
      expect(plate.has_wells?).to eq(false)
      something_else = create(:asset)
      expect(something_else.has_wells?).to eq(false)
    end
  end

  context '#print_machine_barcode?' do
    let(:asset) { create(:asset) }
    it 'returns true when the asset has a barcode format of machine barcode' do
      asset.facts << create(:fact, predicate: 'barcodeFormat', object: 'machine_barcode', literal: true)
      expect(asset.print_machine_barcode?).to be_truthy
    end
    it 'returns false when the asset does not have a setting' do
      expect(asset.print_machine_barcode?).to be_falsy
    end
  end

  context '#barcode_formatted_for_printing' do
    let(:human_barcode) { 'EG1234E' }
    let(:machine_barcode) { 1_420_001_234_690 }
    let(:asset) { create(:asset, barcode: human_barcode) }

    context 'when no specific barcode format has been selected' do
      it 'returns the human barcode' do
        expect(asset.barcode_formatted_for_printing).to eq(human_barcode)
      end
    end
    context 'when machine barcode has been selected' do
      before { asset.facts << create(:fact, predicate: 'barcodeFormat', object: 'machine_barcode', literal: true) }
      context 'when we can generate the machine barcode' do
        it 'returns the machine barcode' do
          expect(asset.barcode_formatted_for_printing).to eq(machine_barcode.to_s)
        end
      end
    end
  end

  context '#printable_object' do
    let(:human_barcode) { 'EG1234E' }
    let(:machine_barcode) { 1_420_001_234_690 }
    let(:asset) { create(:asset, barcode: human_barcode) }

    context 'when is a plate' do
      before { asset.facts << create(:fact, predicate: 'a', object: 'Plate', literal: true) }
      it 'generates a plate printable object' do
        expect(asset.printable_object.has_key?(:top_left))
      end
    end
    context 'when is a tube' do
      before { asset.facts << create(:fact, predicate: 'a', object: 'Tube', literal: true) }
      it 'generates a tube printable object' do
        expect(asset.printable_object.has_key?(:barcode2d))
      end
      context 'when no machine barcode has been selected' do
        it 'generates a tube printable object' do
          expect(asset.printable_object.has_key?(:barcode2d))
        end
      end
      context 'when machine barcode has been selected' do
        before { asset.facts << create(:fact, predicate: 'barcodeFormat', object: 'machine_barcode', literal: true) }
        it 'prints the human barcode in the top line' do
          expect(asset.printable_object[:top_line]).to eq(human_barcode)
        end
        it 'prints the machine barcode as barcode' do
          expect(asset.printable_object[:barcode]).to eq(machine_barcode.to_s)
        end
        it 'prints the machine barcode as barcode 2d' do
          expect(asset.printable_object[:barcode2d]).to eq(machine_barcode.to_s)
        end
      end
    end
  end

  context '#study_name' do
    let(:study) { 'A STUDY' }
    context 'if it is a tube' do
      it 'returns the study name of the tube' do
        tube = create :asset
        tube.facts << create(:fact, predicate: 'a', object: 'Tube')
        tube.facts << create(:fact, predicate: 'study_name', object: study)
        expect(tube.study_name).to eq(study)
      end
    end
    context 'if it is a plate' do
      context 'if the plate has a study name property' do
        it 'returns the study name of the tube' do
          plate = create :asset
          plate.facts << create(:fact, predicate: 'a', object: 'Plate')
          plate.facts << create(:fact, predicate: 'study_name', object: study)
          expect(plate.study_name).to eq(study)
        end
      end
      context 'if the plate do not have study name' do
        context 'when the plate has tubes' do
          context 'when the tube does not have a study name' do
            it 'returns empty string' do
              tube = create :asset
              tube.facts << create(:fact, predicate: 'a', object: 'Tube')
              plate = create :asset
              plate.facts << create(:fact, predicate: 'a', object: 'Plate')
              plate.facts << create(:fact, predicate: 'contains', object_asset: tube)
              expect(plate.study_name).to eq('')
            end
          end

          context 'when the tubes have a study name' do
            it 'returns the study name of the first tube' do
              tube = create :asset
              tube.facts << create(:fact, predicate: 'a', object: 'Tube')
              tube.facts << create(:fact, predicate: 'study_name', object: study)

              plate = create :asset
              plate.facts << create(:fact, predicate: 'a', object: 'Plate')
              plate.facts << create(:fact, predicate: 'contains', object_asset: tube)
              expect(plate.study_name).to eq(study)
            end
          end
        end
      end
    end
  end
end
