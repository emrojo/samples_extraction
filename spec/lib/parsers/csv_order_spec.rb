# frozen_string_literal: true
require 'rails_helper'
require 'parsers/csv_order'

RSpec.describe Parsers::CsvOrder do
  def index_to_location_str(i)
    letters = ('A'..'H').to_a
    "#{letters[(i % 8)]}#{(i / 8).to_i + 1}"
  end

  describe 'parses an order' do
    setup do
      @asset_samples = Array.new(96) do |i|
        FactoryGirl.create(:asset, barcode: i + 1)
      end
      @content = @asset_samples.map(&:barcode).join("\n")
      @rack = FactoryGirl.create(:asset)

      @assets_dst = Array.new(96) do |i|
        asset = FactoryGirl.create(:asset, barcode: 'FR' + (11_200_002 + i).to_s)
        asset.add_facts(FactoryGirl.create(:fact,                                              predicate: 'location', object: index_to_location_str(i)))
        asset.add_facts(FactoryGirl.create(:fact,                                              predicate: 'parent', object_asset: @rack))
        asset
      end
      @rack.add_facts(@assets_dst.map do |a|
        FactoryGirl.create(:fact, predicate: 'contains',
                                  object_asset: a)
      end)
    end

    describe 'with valid content' do
      it 'parses correctly' do
        @csv = Parsers::CsvOrder.new(@content)

        expect(@csv.parse).to eq(true)
        expect(@csv.valid?).to eq(true)
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvOrder.new("1\n2\n3\n97\n")
        expect(@csv.valid?).to eq(false)
      end
    end

    describe 'when linking it with an asset' do
      setup do
        @step_type = FactoryGirl.create(:step_type)
        @asset_group = FactoryGirl.create(:asset_group)
        @step = FactoryGirl.create(:step, step_type: @step_type,
                                          asset_group: @asset_group)
      end

      it 'adds the facts to the asset' do
        @csv = Parsers::CsvOrder.new(@content)
        @csv.add_facts_to(@rack, @step)

        @rack.facts.reload
        facts_for_rack = @rack.facts.with_predicate('contains')
        @asset_samples.each_with_index do |asset_sample, idx|
          expect(asset_sample.facts.with_predicate('transfer').first.object_asset).to eq(facts_for_rack[idx].object_asset)
          expect(facts_for_rack[idx].object_asset.facts.with_predicate('transferredFrom').first.object_asset).to eq(asset_sample)
        end
      end
    end
  end
end
