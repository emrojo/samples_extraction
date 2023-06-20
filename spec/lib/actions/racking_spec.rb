require 'rails_helper'
require 'actions/racking'

RSpec.describe Actions::Racking do
  let(:content) { File.read('test/data/layout.csv') }
  let(:file) { create(:uploaded_file, data: content) }
  let(:activity) { create(:activity) }
  let(:asset_group) { create(:asset_group, assets: [asset]) }
  let(:asset) { create :asset, uploaded_file: file, a: 'TubeRack' }
  let(:step_type) { create(:step_type, condition_groups: [condition_group]) }
  let(:step) do
    create :step, activity: activity, state: Step::STATE_RUNNING, asset_group: asset_group, step_type: step_type
  end

  let(:condition) { create(:condition, predicate: 'a', object: 'TubeRack') }
  let(:condition_group) { create(:condition_group, conditions: [condition]) }
  let(:racking_class) do
    Class.new do
      include Actions::Racking
      attr_reader :asset_group

      def initialize(asset_group)
        @asset_group = asset_group
      end
    end
  end

  # @todo Use racking_class exclusively
  include Actions::Racking

  setup { allow(SequencescapeClient).to receive(:labware).and_return([]) }

  shared_examples_for 'rack_layout' do
    describe 'when linking it with an asset' do
      it 'adds the facts to the asset' do
        expect(asset.facts.count).to eq(1)
        updates = send(method)
        updates.apply(step)

        asset.facts.reload
        assets = asset.facts.with_predicate('contains').map(&:object_asset)
        expect(assets.count).to eq(96)
        assets.each do |a|
          expect(a.facts.with_predicate('location').count).to eq(1)
          expect(a.facts.with_predicate('parent').count).to eq(1)
          expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
        end
      end

      describe 'with links with previous parents' do
        let(:actual_parent) { create(:asset, uploaded_file: file, a: 'TubeRack') }

        it 'removes links with the previous parents' do
          asset_group
          send(method).apply(step)
          asset.facts.reload
          assets = asset.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(96)
          assets.each do |a|
            expect(a.facts.with_predicate('location').count).to eq(1)
            expect(a.facts.with_predicate('parent').count).to eq(1)
            expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
          end

          asset_group = AssetGroup.create(assets: [actual_parent])

          another_step =
            Step.new(activity: activity, asset_group: asset_group, step_type: step_type, state: Step::STATE_RUNNING)

          racking_class.new(asset_group).send(method).apply(another_step)

          assets = asset.reload.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(0)

          assets =
            actual_parent.reload.facts.with_predicate('contains').includes(object_asset: :facts).map(&:object_asset)
          expect(assets.count).to eq(96)

          assets.each do |a|
            expect(a.facts.with_predicate('location').count).to eq(1)
            expect(a.facts.with_predicate('parent').count).to eq(1)
            expect(a.facts.with_predicate('parent').first.object_asset).to eq(actual_parent)
          end
        end
      end

      describe 'with empty slots in the layout .csv' do
        let(:num_empty) { 3 }
        let(:start_pos) { 0 }
        let(:content) { add_empty_slots(File.read('test/data/layout.csv'), num_empty, start_pos) }
        def add_empty_slots(content, num_empty, start_pos = 0)
          csv = CSV.new(content).to_a
          num_empty.times { |i| csv[start_pos + i][1] = 'No Read' }
          csv.map { |line| line.join(',') }.join("\n")
        end

        it 'adds the new facts to the asset and removes the old ones' do
          expect(asset.facts.count).to eq(1)
          send(method).apply(step)

          asset.facts.reload
          assets = asset.facts.with_predicate('contains').map(&:object_asset)
          expect(assets.count).to eq(96 - num_empty)
          assets.each_with_index do |a, idx|
            if (idx < start_pos) || (idx >= start_pos + num_empty)
              expect(a.facts.with_predicate('location').count).to eq(1)
              expect(a.facts.with_predicate('parent').count).to eq(1)
              expect(a.facts.with_predicate('parent').first.object_asset).to eq(asset)
            end
          end
        end
      end
    end
  end

  describe '#fact_changes_for_rack_when_unracking_tubes' do
    let(:tubes) do
      [create(:asset, study_name: 'STDY2'), *create_list(:asset, 2, study_name: 'STDY1', aliquot_type: aliquot_type)]
    end
    let(:aliquot_type) { nil }

    before { tubes.each { |tube| create(:fact, asset: asset, predicate: 'contains', object_asset: tube) } }

    it 'removes all the different studies for this rack when all tubes go out' do
      updates = fact_changes_for_rack_when_unracking_tubes(asset, tubes)
      expect(updates.to_h[:remove_facts].select { |triple| triple[1] == 'study_name' }.pluck(2).sort).to eq(
        %w[STDY1 STDY2]
      )
    end

    context 'when a DNA tube' do
      let(:aliquot_type) { 'DNA' }
      it 'removes the purpose when all tubes go out' do
        updates = fact_changes_for_rack_when_unracking_tubes(asset, tubes)
        expect(updates.to_h[:remove_facts].select { |triple| triple[1] == 'purpose' }.pluck(2).sort).to eq(
          ['DNA Stock Plate']
        )
      end
    end

    it 'only returns the studies of the tubes that are going to be removed' do
      updates = fact_changes_for_rack_when_unracking_tubes(asset, tubes[1..])
      expect(updates.to_h[:remove_facts].select { |triple| triple[1] == 'study_name' }.pluck(2).sort).to eq(['STDY1'])
    end
  end

  describe '#fact_changes_for_rack_when_racking_tubes' do
    subject(:updates) { fact_changes_for_rack_when_racking_tubes(asset, tubes) }

    let(:tubes) do
      [create(:asset, study_name: 'STDY2'), *create_list(:asset, 2, study_name: 'STDY1', aliquot_type: aliquot_type)]
    end
    let(:aliquot_type) { nil }

    it 'returns all the different studies for this rack' do
      expect(
        updates.to_h[:add_facts]
          .select { |_uuid, predicate, _object| predicate == 'study_name' }
          .map { |_uuid, _predicate, object| object }
      ).to match_array(%w[STDY1 STDY2])
    end
    context 'when a DNA tube' do
      let(:aliquot_type) { 'DNA' }

      it 'generates the DNA stock plate purpose' do
        expect(updates.to_h[:add_facts].find { |triple| triple[1] == 'purpose' }[2]).to eq('DNA Stock Plate')
      end
    end
    context 'when an RNA tube' do
      let(:aliquot_type) { 'RNA' }

      it 'generates the RNA stock plate purpose' do
        expect(updates.to_h[:add_facts].find { |triple| triple[1] == 'purpose' }[2]).to eq('RNA Stock Plate')
      end
    end
  end

  describe '#rack_layout' do
    before do
      csv = CSV.new(File.read('test/data/layout.csv')).to_a
      @tubes = csv.map { |line| create(:asset, barcode: line[1]) }
    end
    let(:method) { :rack_layout }
    it_behaves_like('rack_layout')
  end

  describe '#rack_layout_creating_tubes' do
    let(:method) { :rack_layout_creating_tubes }
    it_behaves_like('rack_layout')
  end
end
