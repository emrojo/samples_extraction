# frozen_string_literal: true
require 'rails_helper'

class MyTest < ActivityChannel
  # rubocop:disable Lint/MissingSuper
  def initialize
    nil
  end
  # rubocop:enable Lint/MissingSuper
end

RSpec.describe ActivityChannel, type: :channel do
  context '#receive' do
    context 'when receiving a asset group' do
      let(:instance) { MyTest.new }
      let(:activity) { create :activity }
      let(:group) { create :asset_group, activity_owner: activity }
      let(:assets) { [] }

      before { allow(AssetGroup).to receive(:find).with(group.id).and_return(group) }

      it 'processes asset group with no errors' do
        expect(instance).to receive(:process_asset_group)
        expect(activity).not_to receive(:report_error)
        instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
      end

      context 'when receiving uuids' do
        let!(:tubes) { [create(:asset, uuid: assets[0]), create(:asset, uuid: assets[1])] }
        let(:assets) { [SecureRandom.uuid, SecureRandom.uuid] }
        it 'imports uuids' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with([])
          expect(group).to receive(:update_with_assets).with(tubes)
          expect(activity).not_to receive(:report_error)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving human barcodes' do
        let(:tubes) { [create(:asset, barcode: 'human1'), create(:asset, barcode: 'human2')] }
        let(:assets) { tubes.map(&:barcode) }

        it 'imports human barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(assets)
          expect(group).to receive(:update_with_assets).with(tubes)
          expect(activity).not_to receive(:report_error)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving machine barcodes' do
        let!(:tubes) { [create(:asset, barcode: 'NT1767662F'), create(:asset, barcode: 'NT1767663G')] }
        let(:human_barcodes) { tubes.map(&:barcode) }
        let(:assets) { %w[3981767662700 3981767663714] }

        it 'imports machines barcodes' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes)
          expect(group).to receive(:update_with_assets).with(tubes)
          expect(activity).not_to receive(:report_error)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving all different types of inputs' do
        let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
        let(:uuid_assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
        let(:human_assets) do
          [
            create(:asset, barcode: 'human1'),
            create(:asset, barcode: 'human2'),
            create(:asset, barcode: 'NT1767662F'),
            create(:asset, barcode: 'NT1767663G')
          ]
        end
        let(:human_barcodes) { %w[human1 human2 NT1767662F NT1767663G] }
        let(:assets) { ['human1', 'human2', uuids[0], uuids[1], '3981767662700', '3981767663714'] }
        let(:tubes) do
          [human_assets[0], human_assets[1], uuid_assets[0], uuid_assets[1], human_assets[2], human_assets[3]]
        end

        it 'imports all inputs right' do
          expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(human_assets)
          expect(group).to receive(:update_with_assets).with(tubes)
          expect(activity).not_to receive(:report_error)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end

      context 'when receiving missing inputs' do
        let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
        let(:uuid_assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
        let(:human_assets) do
          [
            create(:asset, barcode: 'human1'),
            create(:asset, barcode: 'human2'),
            create(:asset, barcode: 'NT1767662F'),
            create(:asset, barcode: 'NT1767663G')
          ]
        end
        let(:human_barcodes) { %w[human1 human2 NT1767662F NT1767663G] }
        let(:missing) { SecureRandom.uuid }
        let(:assets) { ['human1', 'human2', uuids[0], uuids[1], '3981767662700', '3981767663714', missing] }
        let(:tubes) do
          [human_assets[0], human_assets[1], uuid_assets[0], uuid_assets[1], human_assets[2], human_assets[3]]
        end

        before { expect(Asset).to receive(:find_or_import_assets_with_barcodes) }

        it 'imports all present inputs right' do
          expect(activity).to receive(:report_error)
          expect(group).to receive(:update_with_assets).with(tubes)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
        it 'detects the error right' do
          expect(activity).to receive(:report_error)
          instance.receive({ 'asset_group' => { id: group.id, assets: assets } })
        end
      end
    end
  end
  context 'ActivityChannel::BarcodeInputResolver' do
    context 'with uuids' do
      let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let!(:assets) { [create(:asset, uuid: uuids[0]), create(:asset, uuid: uuids[1])] }
      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with([]).and_return([])
        resolver = ActivityChannel::BarcodeInputResolver.new
        uuids.each { |uuid| resolver.add_input(uuid) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with human barcodes' do
      let(:assets) { [create(:asset, barcode: 'human1'), create(:asset, barcode: 'human2')] }
      let(:human_barcodes) { assets.map(&:barcode) }
      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        human_barcodes.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with machine barcodes' do
      let!(:assets) { [create(:asset, barcode: 'NT1767662F'), create(:asset, barcode: 'NT1767663G')] }
      let(:human_barcodes) { assets.map(&:barcode) }
      let(:machine_barcodes) { %w[3981767662700 3981767663714] }

      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        machine_barcodes.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with inputs that fail when converting to human barcodes' do
      let!(:assets) { [create(:asset, barcode: 'NT1767662F'), create(:asset, barcode: 'NT1767663G')] }
      let(:wrong_human_barcode) { '1234' }
      let(:human_barcodes) { assets.map(&:barcode).push(wrong_human_barcode) }
      let(:inputs) { ['3981767662700', '3981767663714', wrong_human_barcode] }

      it 'can resolve uuids' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        inputs.each { |barcode| resolver.add_input(barcode) }
        expect(resolver.resolved_assets.assets).to eq(assets)
      end

      it 'can ignore nil inputs' do
        expect(Asset).to receive(:find_or_import_assets_with_barcodes).with(human_barcodes).and_return(assets)
        resolver = ActivityChannel::BarcodeInputResolver.new
        inputs.each { |barcode| resolver.add_input(barcode) }
        resolver.add_input(nil)
        expect(resolver.resolved_assets.assets).to eq(assets)
      end
    end
    context 'with mixed content' do
      let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let(:inputs) { ['human1', uuids[0], '3981767663714', 'human2', '3981767662700', uuids[1]] }
      let(:human_barcodes) { %w[human1 NT1767663G human2 NT1767662F] }
      let!(:assets) do
        [
          create(:asset, barcode: 'human1'),
          create(:asset, uuid: uuids[0]),
          create(:asset, barcode: 'NT1767663G'), # EAN13: 3981767663714
          create(:asset, barcode: 'human2'),
          create(:asset, barcode: 'NT1767662F'), # EAN13: 3981767662700
          create(:asset, uuid: uuids[1])
        ]
      end
      let(:obtained_uuid_assets) { [assets[1], assets[5]] }
      let!(:obtained_human_assets) { [assets[0], assets[2], assets[3], assets[4]] }
      let(:machine_barcodes) { %w[3981767663714 3981767662700] }

      before { expect(Asset).to receive(:find_or_import_assets_with_barcodes) }

      context 'without missing assets' do
        it 'can find all elements in order' do
          resolver = ActivityChannel::BarcodeInputResolver.new
          inputs.each { |barcode| resolver.add_input(barcode) }
          expect(resolver.resolved_assets.assets).to eq(assets)
          expect(resolver.resolved_assets.missing_inputs).to eq([])
        end
      end

      context 'with missing assets' do
        context 'when the asset missing is a barcode' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return(obtained_uuid_assets.shuffle)
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return(obtained_human_assets.shuffle)
          end
          let(:obtained_human_assets) { [assets[0], nil, assets[3], assets[4]] }
          let(:obtained_assets) { [assets[0], assets[1], assets[3], assets[4], assets[5]] }
          let(:missing_inputs) { [inputs[2]] }
          it 'can handle missing barcodes' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }
            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end
        context 'when the asset missing is an uuid' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return(obtained_uuid_assets.shuffle)
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return(obtained_human_assets.shuffle)
          end
          let(:obtained_uuid_assets) { [assets[1], nil] }
          let(:obtained_assets) { [assets[0], assets[1], assets[2], assets[3], assets[4]] }
          let(:missing_inputs) { [inputs[5]] }
          it 'can handle missing uuids' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }

            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end

        context 'when there are several elements missing' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return(obtained_uuid_assets.shuffle)
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return(obtained_human_assets.shuffle)
          end
          let(:obtained_uuid_assets) { [nil, assets[5]] }
          let(:obtained_human_assets) { [assets[0], nil, nil, assets[4]] }
          let(:obtained_assets) { [assets[0], assets[4], assets[5]] }
          let(:missing_inputs) { [inputs[1], inputs[2], inputs[3]] }
          it 'can handle missing both uuids and barcodes' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }

            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end

        context 'when all uuids are missing' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return([])
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return(obtained_human_assets.shuffle)
          end
          let(:obtained_assets) { [assets[0], assets[2], assets[3], assets[4]] }
          let(:missing_inputs) { [inputs[1], inputs[5]] }
          it 'can handle all uuids missing' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }

            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end

        context 'when all barcodes are missing' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return(obtained_uuid_assets.shuffle)
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return([])
          end
          let(:obtained_assets) { [assets[1], assets[5]] }
          let(:missing_inputs) { [inputs[0], inputs[2], inputs[3], inputs[4]] }
          it 'can handle all barcodes missing' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }

            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end

        context 'when all inputs are missing' do
          before do
            expect(Asset).to receive(:where).with(uuid: uuids).and_return([])
            expect(Asset).to receive(:where).with(barcode: human_barcodes).and_return([])
          end
          let(:obtained_assets) { [] }
          let(:missing_inputs) { inputs }
          it 'can handle all inputs missing' do
            resolver = ActivityChannel::BarcodeInputResolver.new
            inputs.each { |barcode| resolver.add_input(barcode) }

            expect(resolver.resolved_assets.assets).to eq(obtained_assets)
            expect(resolver.resolved_assets.missing_inputs).to eq(missing_inputs)
          end
        end
      end
    end
  end
end
