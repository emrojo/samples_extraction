requrie 'rails_helper'

RSpec.describe LabelTemplate do
  context '#external_id_for_type' do
    context 'when it cannot find any remote label template' do
      it 'returns nil' do
        allow(PMB::LabelTemplate).to receive(:where).and_return([])
        expect(LabelTemplate.external_id_for_type("UNMATCH")).to eq(nil)
      end
    end
    context 'when it cannot find a template for the specified type' do
      it 'returns nil ' do
        lt = create(:label_template, template_type: type, name: template_name)

        allow(PMB::LabelTemplate).to receive(:where).and_return([matched_template])
      end
    end
  end
end
