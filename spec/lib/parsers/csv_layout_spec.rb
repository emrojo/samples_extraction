# frozen_string_literal: true
require 'rails_helper'
require 'parsers/csv_layout'
require 'csv'

RSpec.describe Parsers::CsvLayout do
  describe 'parses a layout' do
    setup do
      @content = File.open('test/data/layout.csv')
      @assets = Array.new(96) do |i|
        FactoryGirl.create(:asset, barcode: 'FR' + (11_200_002 + i).to_s)
      end
    end

    describe 'with valid content' do
      it 'parses correctly' do
        @csv = Parsers::CsvLayout.new(@content)

        expect(@csv.parse).to eq(true)
        expect(@csv.valid?).to eq(true)
      end

      it 'recognise incorrect csv files' do
        @csv = Parsers::CsvLayout.new('1,2,3,4,5')
        expect(@csv.valid?).to eq(false)
      end
    end

    describe 'when linking it with an asset' do
      setup do
        @asset = FactoryGirl.create(:asset)
        @step_type = FactoryGirl.create(:step_type)
        @asset_group = FactoryGirl.create(:asset_group)
        @step = FactoryGirl.create(:step, step_type: @step_type,
                                          asset_group: @asset_group)
      end

      it 'adds the facts to the asset' do
        @csv = Parsers::CsvLayout.new(@content)
        expect(@asset.facts.count).to eq(0)
        @csv.add_facts_to(@asset, @step)
        @asset.facts.reload
        expect(@asset.facts.with_predicate('contains').count).to eq(96)
        @assets.each do |a|
          expect(a.facts.with_predicate('location').count).to eq(1)
          expect(a.facts.with_predicate('parent').count).to eq(1)
          expect(a.facts.with_predicate('parent').first.object_asset).to eq(@asset)
        end
      end

      describe 'with empty slots in the layout .csv' do
        def add_empty_slots(content, num_empty, start_pos = 0)
          csv = CSV.new(content).to_a
          num_empty.times do |i|
            csv[start_pos + i][1] = 'No Read'
          end
          csv.map do |line|
            line.join(',')
          end.join("\n")
        end

        setup do
          @asset2 = FactoryGirl.create(:asset)
          @csv = Parsers::CsvLayout.new(@content)
          @csv.add_facts_to(@asset2, @step)
          @step.finish
          @content = File.open('test/data/layout.csv')

          @step = FactoryGirl.create(:step, step_type: @step_type,
                                            asset_group: @asset_group)
        end

        it 'adds the new facts to the asset and removes the old ones' do
          @num_empty = 3
          @start_pos = 0
          @csv = Parsers::CsvLayout.new(add_empty_slots(@content, @num_empty, @start_pos))
          expect(@asset2.facts.with_predicate('contains').count).to eq(96)
          @csv.add_facts_to(@asset2, @step)
          @step.finish
          @asset2.facts.reload
          expect(@asset2.facts.with_predicate('contains').count).to eq(96 - @num_empty)
          @assets.each_with_index do |a, idx|
            next unless (idx < @start_pos) || (idx >= @start_pos + @num_empty)
            expect(a.facts.with_predicate('location').count).to eq(1)
            expect(a.facts.with_predicate('parent').count).to eq(1)
            expect(a.facts.with_predicate('parent').first.object_asset).to eq(@asset2)
          end
        end
      end

      describe 'with links with previous parents' do
        setup do
          @former_parent = FactoryGirl.create(:asset)
          @assets.each_with_index do |a, location_index|
            @former_parent.add_facts(FactoryGirl.create(:fact, predicate: 'contains', object_asset: a))
            a.facts << [FactoryGirl.create(:fact, predicate: 'parent',
                                                  object_asset: @former_parent), FactoryGirl.create(:fact, predicate: 'location',
                                                                                                           object: location_index.to_s)]
          end
        end

        it 'removes links with the previous parents' do
          @csv = Parsers::CsvLayout.new(@content)
          expect(@asset.facts.count).to eq(0)
          @csv.add_facts_to(@asset, @step)
          @asset.facts.reload
          expect(@asset.facts.with_predicate('contains').not_to_remove.count).to eq(96)
          @assets.each do |a|
            expect(a.facts.with_predicate('location').not_to_remove.count).to eq(1)
            expect(a.facts.with_predicate('parent').not_to_remove.count).to eq(1)
            expect(a.facts.with_predicate('parent').not_to_remove.first.object_asset).to eq(@asset)
          end
        end
      end
    end
  end
end
