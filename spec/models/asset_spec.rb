require 'rails_helper'
RSpec.describe Asset do
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
      asset.facts << create(:fact, predicate: 'barcodeFormat', object: 'machine_barcode',
        literal: true)
      expect(asset.print_machine_barcode?).to be_truthy
    end
    it 'returns false when the asset does not have a setting' do
      expect(asset.print_machine_barcode?).to be_falsy
    end
  end

  context '#barcode_formatted_for_printing' do
    let(:human_barcode) { "EG1234E" }
    let(:machine_barcode) { 1420001234690 }
    let(:asset) { create(:asset, barcode: human_barcode) }

    context 'when no specific barcode format has been selected' do
      it 'returns the human barcode' do
        expect(asset.barcode_formatted_for_printing).to eq(human_barcode)
      end
    end
    context 'when machine barcode has been selected' do
      before do
        asset.facts << create(:fact, predicate: 'barcodeFormat', object: 'machine_barcode',
          literal: true)
      end
      context 'when we can generate the machine barcode' do
        it 'returns the machine barcode' do
          expect(asset.barcode_formatted_for_printing).to eq(machine_barcode.to_s)
        end
      end
    end
  end

  context '#printable_object' do
    let(:human_barcode) { "EG1234E" }
    let(:machine_barcode) { 1420001234690 }
    let(:asset) { create(:asset, barcode: human_barcode) }

    context 'when is a plate' do
      before do
        asset.facts << create(:fact, predicate: 'a', object: 'Plate', literal: true)
      end
      it 'generates a plate printable object' do
        expect(asset.printable_object[:label].has_key?(:top_left))
      end
    end
    context 'when is a tube' do
      before do
        asset.facts << create(:fact, predicate: 'a', object: 'Tube', literal: true)
      end
      it 'generates a tube printable object' do
        expect(asset.printable_object[:label].has_key?(:barcode2d))
      end
      context 'when no machine barcode has been selected' do
        it 'generates a tube printable object' do
          expect(asset.printable_object[:label].has_key?(:barcode2d))
        end
      end
      context 'when machine barcode has been selected' do
        before do
          asset.facts << create(:fact, predicate: 'barcodeFormat',
            object: 'machine_barcode', literal: true)
        end
        it 'prints the human barcode in the top line' do
          expect(asset.printable_object[:label][:top_line]).to eq(human_barcode)
        end
        it 'prints the machine barcode as barcode' do
          expect(asset.printable_object[:label][:barcode]).to eq(machine_barcode.to_s)
        end
        it 'prints the machine barcode as barcode 2d' do
          expect(asset.printable_object[:label][:barcode2d]).to eq(machine_barcode.to_s)
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
