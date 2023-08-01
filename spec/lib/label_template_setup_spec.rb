# frozen_string_literal: true

require 'rails_helper'
require './lib/label_template_setup'

RSpec.describe LabelTemplateSetup do
  before do
    allow(PMB::LabelType).to receive(:all).and_return([PMB::LabelType.new(name: 'Plate', id: 1)])
    allow(PMB::LabelTemplate).to receive(:all).and_return([])
  end

  describe '::remove_old_templates!' do
    before do
      create :plate_label_template, name: 'Old template', template_type: 'DEPRECATED_PLATE'
      create :plate_label_template, name: 'New template'
      described_class.register_template('New template', 'Plate') { {} }
      described_class.remove_old_templates!
    end

    it 'removes unregistered templates' do
      expect(LabelTemplate.pluck(:name)).not_to include('Old template')
    end

    it 'leaves registered templates' do
      expect(LabelTemplate.pluck(:name)).to include('New template')
    end
  end
end
