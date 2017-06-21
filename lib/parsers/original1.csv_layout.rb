# frozen_string_literal: true
require 'csv'

module Parsers
  class CsvLayout
    attr_reader :csv_parser, :errors, :data, :parsed

    def create_tubes?
      false
    end

    def initialize(str)
      @csv_parser = CSV.new(str)
      @errors = []
      @parsed = false
    end

    def parsed?
      @parsed
    end

    def duplicated(sym)
      all_elems = @data.map { |obj| obj[sym] }
      all_elems.select do |element|
        !element.nil? && (all_elems.count(element) > 1)
      end.uniq.compact
    end

    def location_str(location)
      location[0] + location[1..location.length].to_i.to_s
    end

    def builder(barcode)
      if create_tubes?
        asset = Asset.find_by_barcode(barcode)
        asset = Asset.create!(barcode: barcode) unless asset
        asset.add_facts([Fact.new(predicate: 'a', object: 'Tube')])
      else
        asset = Asset.find_by_barcode(barcode)
      end
      asset
    end

    def valid_location?(location)
      !!location.match(/[A-H]\d\d/)
    end

    def valid_fluidx_barcode?(barcode)
      barcode.start_with?('F')
    end

    def no_read_barcode?(barcode)
      barcode.start_with?('No Read')
    end

    def parse
      @data ||= @csv_parser.to_a.map do |line|
        location = line[0].strip
        barcode = line[1].strip
        asset = valid_fluidx_barcode?(barcode) ? builder(barcode) : nil
        @errors.push(msg: "Invalid Fluidx tube barcode format #{barcode}") unless valid_fluidx_barcode?(barcode) || no_read_barcode?(barcode)
        @errors.push(msg: 'Invalid location') unless valid_location?(location)

        if asset.nil? && valid_fluidx_barcode?(barcode)
          @errors.push(msg: "Cannot find the barcode #{barcode}")
        end

        {
          location: location_str(location),
          asset: asset
        }
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

    def layout
      @data
    end

    def add_facts_to(asset, step)
      if valid?
        asset.add_facts(Fact.create(predicate: 'layout', object: 'Complete'))
        facts_to_remove = asset.facts.with_predicate('contains').map do |f|
          [
            f.object_asset.facts.with_predicate('parent'),
            f.object_asset.facts.with_predicate('location'),
            f
          ].flatten.compact
        end.flatten.each do |f|
          f.set_to_remove_by(step.id)
        end
        facts_to_add = @data.map do |obj|
          next if obj[:asset].nil?
          previous_parents = obj[:asset].facts.with_predicate('parent').map(&:object_asset)
          if obj[:asset].respond_to? :facts
            [
              obj[:asset].facts.with_predicate(:location),
              obj[:asset].facts.with_predicate(:parent),
              Fact.where(predicate: 'contains', object_asset: obj[:asset])
            ].flatten.each do |f|
              f.set_to_remove_by(step.id)
            end
          end
          obj[:asset].add_facts([
                                  Fact.create(predicate: 'location', object: obj[:location], to_add_by: step.id),
                                  Fact.create(predicate: 'parent', object_asset: asset, to_add_by: step.id)
                                ])
          obj[:asset].add_facts(previous_parents.map do |previous_parent|
            Fact.create(predicate: 'previousParent', object_asset: previous_parent, to_add_by: step.id)
          end)
          Fact.create(predicate: 'contains', object_asset: obj[:asset], to_add_by: step.id)
        end.compact
        asset.add_facts(facts_to_add) if valid?
        return valid?
      end
      false
    end
  end
end
