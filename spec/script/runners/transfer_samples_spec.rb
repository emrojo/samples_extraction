require 'rails_helper'
require Rails.root.to_s+'/script/runners/transfer_samples'

RSpec.describe 'TransferSamples' do
  let(:sample) { create(:asset, facts: [create(:fact, predicate: 'sample_name', object: 'sample1')]) }
  let(:sources) {
    5.times.map { create(:asset, facts: [
      create(:fact, predicate: 'a', object: 'Tube'),
      create(:fact, predicate: 'study_name', object: 'Study 1'),
      create(:fact, predicate: 'sample_tube', object_asset_id: sample.id)
    ]) }
  }
  let(:destinations) {
    5.times.map { create(:asset, facts: [create(:fact, predicate: 'a', object: 'Tube')]) }
  }
  let(:instance) {
    TransferSamples.new(asset_group: group)
  }

  shared_examples_for 'transfers all facts from source to destination' do
    it 'transfers all facts from source to destination' do
      added_facts = instance.process.to_h[:add_facts]
      study_names_transferred = added_facts.select do |triple|
        triple[1] == 'study_name'
      end.map { |triple| [triple[0], triple[2]] }
      expect(study_names_transferred).to eq(destinations.map(&:uuid).zip(destinations.length.times.map { 'Study 1' }))
      sample_tubes_transferred = added_facts.select do |triple|
        triple[1] == 'sample_tube'
      end.map { |triple| [triple[0], triple[2]] }
      expect(sample_tubes_transferred).to eq(destinations.map(&:uuid).zip(destinations.length.times.map { sample.uuid }))
    end
    context 'when there is no inverse relation transferredFrom' do
      it 'creates the inverse relation transferredFrom' do
        added_facts = instance.process.to_h[:add_facts]
        transferredFrom = added_facts.select do |triple|
          triple[1] == 'transferredFrom'
        end.map { |triple| [triple[0], triple[2]] }
        expect(transferredFrom).to eq(destinations.map(&:uuid).zip(sources.map(&:uuid)))
      end
    end
  end

  context 'when both sources and destinations are in the group' do
    let(:group) { create(:asset_group, assets: [sources, destinations].flatten) }
    context 'when the assets are not related' do
      it 'does nothing with them' do
        expect(instance.process.to_h.keys.length).to eq(0)
      end
    end

    context 'when the assets are related by a transfer' do
      before do
        sources.zip(destinations).each do |s,d|
          s.facts << create(:fact, predicate: 'transfer', object_asset_id: d.id)
        end
      end
      it_behaves_like 'transfers all facts from source to destination'
    end
    context 'when not all the assets are related by a transfer' do
      before do
        sources.first.facts << create(:fact, predicate: 'transfer', object_asset_id: destinations.first.id)
      end
      it 'does nothing with assets not related' do
        added_facts = instance.process.to_h[:add_facts]
        study_names_transferred = added_facts.select do |triple|
          triple[1] == 'study_name'
        end.map { |triple| [triple[0], triple[2]] }
        expect(study_names_transferred).to eq([[destinations.first.uuid, 'Study 1']])
        sample_tubes_transferred = added_facts.select do |triple|
          triple[1] == 'sample_tube'
        end.map { |triple| [triple[0], triple[2]] }
        expect(sample_tubes_transferred).to eq([[destinations.first.uuid, sample.uuid]])
      end
    end
  end
  context 'when only sources are in the group' do
    let(:group) { create(:asset_group, assets: sources) }
    before do
      sources.zip(destinations).each do |s,d|
        s.facts << create(:fact, predicate: 'transfer', object_asset_id: d.id)
      end
    end
    it_behaves_like 'transfers all facts from source to destination'
  end
  context 'when only destinations are in the group' do
    let(:group) { create(:asset_group, assets: destinations) }
    before do
      destinations.zip(sources).each do |d,s|
        d.facts << create(:fact, predicate: 'transferredFrom', object_asset_id: s.id)
      end
    end
    it_behaves_like 'transfers all facts from source to destination'
  end
end

