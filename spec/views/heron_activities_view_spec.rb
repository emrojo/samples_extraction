# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'heron_activities_view' do
  let(:activity_type) { FactoryBot.create :activity_type, name: 'Illumina Extraction' }
  let(:instrument) { FactoryBot.create :instrument, name: 'Instument' }
  let(:kit_type) { FactoryBot.create :kit_type, name: 'Kit type' }
  let(:kit) { FactoryBot.create :kit, kit_type: kit_type }
  let(:user) { FactoryBot.create :user, fullname: 'Users name' }
  let(:well_attributes) { [{ supplier_sample_name: 'Sample A' }, { supplier_sample_name: 'Sample B' }] }
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

  def create_transfer(step:, from:, to:)
    FactoryBot.create :fact, predicate: 'transferredFrom', asset: to, object_asset: from
    FactoryBot.create :operation, predicate: 'transferredFrom', asset: to, step: step, object_asset: from
  end

  before do
    activity
    create_transfer step: first_transfer, from: source_plate, to: intermediate_plate
    create_transfer step: second_transfer, from: intermediate_plate, to: target_plate
  end

  let(:results) { ApplicationRecord.connection.execute('SELECT * FROM heron_activities_view') }

  it 'lists finished activities at the sample level' do
    expect(results.size).to eq 2
  end

  it 'has the expected columns' do
    expect(results.fields).to eq [
         'Supplier sample name',
         'Input barcode',
         'Output barcode',
         'Activity type',
         'Instrument',
         'Kit barcode',
         'Kit type',
         'Date',
         'User',
         '_activity_id_'
       ]
  end

  it 'lists the correct information' do
    expect(results.to_a).to include(
      [
        'Sample A',
        source_plate.barcode,
        target_plate.barcode,
        'Illumina Extraction',
        'Instument',
        kit.barcode,
        'Kit type',
        activity.completed_at,
        'Users name',
        activity.id
      ],
      [
        'Sample B',
        source_plate.barcode,
        target_plate.barcode,
        'Illumina Extraction',
        'Instument',
        kit.barcode,
        'Kit type',
        activity.completed_at,
        'Users name',
        activity.id
      ]
    )
  end
end
