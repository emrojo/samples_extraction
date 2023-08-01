# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Activity do
  let(:activity_type) { FactoryBot.create :activity_type, name: 'Illumina Extraction' }
  let(:instrument) { FactoryBot.create :instrument, name: 'Instument' }
  let(:kit_type) { FactoryBot.create :kit_type, name: 'Kit type' }
  let(:kit) { FactoryBot.create :kit, kit_type: kit_type }
  let(:user) { FactoryBot.create :user, fullname: 'Users name' }
  let(:sample_a_uuid) { SecureRandom.uuid }
  let(:sample_b_uuid) { SecureRandom.uuid }
  let(:well_attributes) do
    [
      # Quotes around UUID reflect what I'm actually seeing in the DB.
      { supplier_sample_name: 'Sample A', sample_uuid: "\"#{sample_a_uuid}\"" },
      { supplier_sample_name: 'Sample B', sample_uuid: "\"#{sample_b_uuid}\"" }
    ]
  end
  let(:target_plate) { FactoryBot.create :plate, well_attributes: well_attributes }
  let(:source_plate) { FactoryBot.create :plate, well_attributes: well_attributes }
  let(:intermediate_plate) { FactoryBot.create :plate, well_attributes: well_attributes }
  let(:asset_group) { FactoryBot.create :asset_group, assets: [target_plate] }
  let(:step_type) { FactoryBot.create :step_type, step_action: 'transfer_plate_to_plate.rb' }

  # Both first and second transfer specifying the same asset group is based
  # on the data I'm actually seeing in production
  let(:first_transfer) { FactoryBot.create :step, step_type: step_type, asset_group: asset_group, user: user }
  let(:second_transfer) { FactoryBot.create :step, step_type: step_type, asset_group: asset_group, user: user }

  let(:activity) do
    FactoryBot.create :finished_activity,
                      activity_type: activity_type,
                      asset_group: asset_group,
                      kit: kit,
                      instrument: instrument,
                      steps: [first_transfer, second_transfer]
  end

  def create_transfer(step:, from:, to:, created_at:)
    FactoryBot.create :fact, predicate: 'transferredFrom', asset: to, object_asset: from, created_at: created_at
    FactoryBot.create :operation, predicate: 'transferredFrom', asset: to, step: step, object_asset: from
  end

  before do
    activity
    create_transfer step: first_transfer, from: source_plate, to: intermediate_plate, created_at: 1.day.ago
    create_transfer step: second_transfer, from: intermediate_plate, to: target_plate, created_at: 1.hour.ago
  end

  subject(:results) { described_class.new(activity).as_json }

  it 'lists finished activities at the sample level' do
    expect(results[:samples_extraction_activity][:samples].length).to eq 2
  end

  it 'has the expected keys' do
    expect(results[:samples_extraction_activity].keys).to eq %i[
         samples
         activity_type
         instrument
         kit_barcode
         kit_type
         completed_at
         updated_at
         user
         activity_id
       ]
  end

  it 'lists the correct information' do
    expect(results).to eq(
      {
        samples_extraction_activity: {
          samples: [
            { sample_uuid: sample_a_uuid, input_barcode: source_plate.barcode, output_barcode: target_plate.barcode },
            { sample_uuid: sample_b_uuid, input_barcode: source_plate.barcode, output_barcode: target_plate.barcode }
          ],
          activity_type: 'Illumina Extraction',
          instrument: 'Instument',
          kit_barcode: kit.barcode,
          kit_type: 'Kit type',
          # created_at: activity.created_at, # Don't really want this
          updated_at: activity.updated_at,
          completed_at: activity.completed_at,
          user: 'Users name',
          activity_id: activity.id
        },
        lims: 'SAMPEXT'
      }
    )
  end

  describe '#routing_key' do
    subject { described_class.new(activity).routing_key }
    it { is_expected.to eq "activity.finished.#{activity.id}" }
  end

  describe '#payload' do
    subject { described_class.new(activity).payload }
    it { is_expected.to eq results.to_json }
  end
end
