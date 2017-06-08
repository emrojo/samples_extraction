# frozen_string_literal: true
require 'rails_helper'
require 'parsers/symphony'

RSpec.describe Parsers::Symphony do
  describe 'parses a symphony file' do
    setup do
      @content = File.open('test/data/symphony.xml')
      @rack = FactoryGirl.create(:asset)
      @tube = FactoryGirl.create(:asset)
      @barcode = '11111111'
      @tube_orig = FactoryGirl.create(:asset, barcode: @barcode)
      @rack.add_facts(FactoryGirl.create(:fact,                                            predicate: 'contains',
                                                                                           object_asset: @tube))
      @tube.add_facts(FactoryGirl.create(:fact,                                            predicate: 'location',
                                                                                           object: 'A1'))
    end

    describe 'with valid content' do
      it 'validates the file' do
        expect(Parsers::Symphony.valid_for?(@content)).to eq(true)
      end

      it 'loads data correctly' do
        msgs = Parsers::Symphony.parse(@content, @rack)

        expect(msgs).to eq([])

        tubes = @rack.facts.with_predicate('contains').map(&:object_asset)

        tube = tubes.select { |tube| tube.facts.with_predicate('location').first.object == 'A1' }.first
        orig_tube = tube.facts.with_predicate('transferredFrom').first.object_asset

        expect(orig_tube.barcode).to eq(@barcode)
      end
    end
  end
end
