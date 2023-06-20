require 'rails_helper'
RSpec.describe 'Activities::StepsManagement' do
  context 'with an activity configuration' do
    let(:asset) do
      create :asset,
             {
               barcode: '1',
               facts:
                 [%w[is_a Tube], %w[is_a ReceptionTube], %w[aliquotType DNA]].map do |a, b|
                   create :fact, { predicate: a, object: b }
                 end
             }
    end
    let(:step_type) do
      create :step_type,
             name: 'Step B',
             condition_groups: [
               create(
                 :condition_group,
                 conditions: [
                   create(:condition, { predicate: 'is_a', object: 'ReceptionTube' }),
                   create(:condition, { predicate: 'aliquotType', object: 'DNA' })
                 ]
               )
             ]
    end
    let(:step_type2) { create :step_type, name: 'Step A' }
    let(:activity_type) { create :activity_type, step_types: [step_type, step_type2] }
    let(:activity) { create :activity, activity_type: activity_type }

    let(:asset_group) { create :asset_group, assets: [asset] }

    it 'identify all the step types' do
      assert_equal activity.step_types, [step_type, step_type2]
    end

    context '#step_types_for' do
      it 'identify the possible step types' do
        assert_equal activity.step_types_for([asset]), [step_type]
      end
    end

    context '#steps_for' do
      it 'identify the steps done' do
        step = create :step, { step_type_id: step_type.id, activity_id: activity.id, asset_group_id: asset_group.id }

        assert_equal activity.steps_for(asset_group.assets), [step]
      end
    end
  end
end
