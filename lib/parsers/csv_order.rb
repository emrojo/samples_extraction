# frozen_string_literal: true
require 'csv'

module Parsers
  class CsvOrder
    attr_reader :csv_parser, :errors, :data, :parsed

    def initialize(str)
      @csv_parser = CSV.new(str)
      @errors = []
      @parsed = false
    end

    def parsed?
      @parsed
    end

    def duplicated(sym)
      return [] unless @data
      all_elems = @data.map { |obj| obj[sym] }
      all_elems.select do |element|
        all_elems.count(element) > 1
      end.uniq.compact
    end

    def parse
      list = @csv_parser.to_a
      @data ||= list.map do |line|
        obj = { asset: nil }
        unless line.nil? || line.empty?
          barcode = line[0]
          asset = Asset.find_by_barcode(barcode)
          @errors.push(msg: "Cannot find the barcode #{barcode}") if asset.nil?
          obj[:asset] = asset
        end
        obj
      end
      unless duplicated(:asset).empty?
        duplicated(:asset).each do |asset|
          @errors.push(msg: "The tube with barcode #{asset.barcode} is duplicated in the file")
        end
      end
      unless duplicated(:location).empty?
        duplicated(:location).each do |location|
          @errors.push(msg: "The location #{location} is duplicated in the file")
        end
      end
      @parsed = true
      valid?
    end

    def valid?
      parse unless @parsed
      @data && @errors.empty?
    end

    def sample_tubes
      @data if valid?
    end

    def locations_by_column
      Array.new(12) do |col|
        ('A'..'H').to_a.map do |l|
          "#{l}#{col + 1}"
        end
      end.flatten
    end

    def add_facts_to(rack, step)
      if valid?
        rack.add_facts(Fact.create(predicate: 'order', object: 'Complete'))
        rack_tubes_by_location = rack.facts.with_predicate('contains').map(&:object_asset).each_with_object({}) do |tube, memo|
          location = tube.facts.with_predicate('location').first.object
          memo[location] = tube
        end

        locations_by_column.each_with_index do |location, index|
          next unless index < sample_tubes.length
          sample_tube = sample_tubes[index][:asset]
          next unless sample_tube
          tube = rack_tubes_by_location[location]
          if tube
            sample_tube.add_facts(Fact.create(predicate: 'transfer', object_asset: tube, to_add_by: step.id))
            tube.add_facts(Fact.create(predicate: 'transferredFrom', object_asset: sample_tube, to_add_by: step.id))
          end
        end
      end
    end
  end
end
