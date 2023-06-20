# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Printables::Summary do
  subject(:summary) { described_class.new }

  before do
    summary.add_labels('printer 1', 1)
    summary.add_labels('printer 2', 2)
    summary.add_labels('printer 3', 3)
    summary.add_labels('printer 2', 2)
  end

  describe '#to_s' do
    subject { summary.to_s }
    it { is_expected.to eq('1 labels sent to printer 1, 4 labels sent to printer 2, and 3 labels sent to printer 3') }
  end
end
