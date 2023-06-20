# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelTemplate, type: :model do
  context '#for_type' do
    let!(:templates) { [create(:plate_label_template), create(:tube_label_template)] }

    context 'when obtaining a template' do
      it 'returns a valid template for each case' do
        expect(LabelTemplate.for_type('Tube')).to eq(templates[1])
        expect(LabelTemplate.for_type('Plate')).to eq(templates[0])
      end
    end

    context 'when using the wrong template' do
      let(:message) do
        "Could not find any label template for type 'Bubidibu'. Please contact LIMS support to fix the problem"
      end

      it 'raise error' do
        expect { LabelTemplate.for_type('Bubidibu') }.to raise_error RuntimeError, message
      end
    end

    context 'when using the template of an alias labware type' do
      it 'returns a valid template for each case' do
        expect(LabelTemplate.for_type('SampleTube')).to eq(templates[1])
        expect(LabelTemplate.for_type('TubeRack')).to eq(templates[0])
      end
    end
  end
end
