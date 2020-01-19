require 'rails_helper'

RSpec.describe 'Callbacks::BarcodeCallbacks' do
  let(:updates) { FactChanges.new }
  let(:inference) { Step.new }
  let(:rack) { create :tube_rack }

  context 'when changing barcode' do
    let(:barcode) {"1234"}

    context 'when adding a barcode fact' do
      let(:asset) { create :asset}

      it 'sets the barcode into the barcode column of the asset' do
        updates.add(asset, 'barcode', barcode)
        expect{updates.apply(inference)}.to change{asset.barcode}.from(nil).to(barcode)
      end

      it 'adds the barcode fact to the asset' do
        updates.add(asset, 'barcode', barcode)
        expect{updates.apply(inference)}.to change{asset.facts.where(predicate: 'barcode').count}.from(0).to(1)
      end

      it 'adds an add operation for it' do
        updates.add(asset, 'barcode', barcode)
        updates.apply(inference)
        inference.reload
        inference.operations.reload
        expect(inference.operations.where(action_type: 'addFacts', predicate: 'barcode').count).not_to eq(0)

      end
    end
    context 'when removing a barcode fact' do
      let(:asset) { create :asset, barcode: barcode}

      it 'removes the barcode from the column of the asset' do
        updates.remove_where(asset, 'barcode', barcode)
        expect{updates.apply(inference)}.to change{asset.barcode}.from(barcode).to(nil)
      end
      it 'removes the barcode fact from the asset' do
        updates.remove_where(asset, 'barcode', barcode)
        updates.apply(inference)
        expect(asset.facts.where(predicate: 'barcode').count).to eq(0)
      end

      it 'adds a remove operation for it' do
        updates.remove_where(asset, 'barcode', barcode)
        updates.apply(inference)
        inference.reload
        inference.operations.reload
        expect(inference.operations.where(action_type: 'removeFacts', predicate: 'barcode').count).not_to eq(0)
      end

    end
  end

end
