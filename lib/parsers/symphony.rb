# frozen_string_literal: true
require 'pry'
module Parsers
  class Symphony
    SYMPHONY_NAMESPACE = 'Symphony'

    attr_accessor :error_messages
    attr_reader :doc
    def initialize(str)
      @error_messages = []
      @doc = Nokogiri::XML(str)
    end

    def self.valid_for?(str)
      Nokogiri::XML(str).xpath('FullPlateTrack').count == 1
    end

    def tube_at_location(rack, location)
      tubes = rack.facts.with_predicate('contains').map(&:object_asset)
      return nil if tubes.empty?
      tubes.select { |t| t.facts.with_fact('location', location).count > 0 }.first
    end

    def apply_to_rack(rack)
      apply_symphony_facts_to_rack(rack)
      reasoning_with_symphony_facts(rack)
    end

    def reasoning_with_symphony_facts(rack)
      #
      #  {
      #   ?rack :contains ?tubeInRack .
      #   ?tubeInRack Symphony:SampleCode ?barcode .
      #   ?tubePrevious :barcode ?barcode
      #  } => {
      #   :step :addFacts { ?tubePrevious :transfer ?tubeInRack . }.
      #   :step :removeFacts { ?tubeInRack Symphony:SampleCode ?barcode . } .
      #  } .
      #  {
      #   ?rack :contains ?tubeInRack .
      #   ?tubeInRack Symphony:SampleOutputVolume ?volume .
      #  } => {
      #   :step :addFacts { ?tubeInRack :volume ?volume . } .
      #   :step :removeFacts { ?tubeInRack Symphony:SampleOutputVolume ?volume . } .
      #  } .
      #
      tubes = rack.facts.with_predicate('contains').map(&:object_asset)
      tubes.each do |tube|
        tube.facts.with_ns_predicate(Parsers::Symphony::SYMPHONY_NAMESPACE).each do |f|
          if f.predicate == 'SampleCode'
            asset = Asset.find_or_import_asset_with_barcode(f.object)
            asset.add_facts([
                              Fact.create(predicate: 'transfer', object_asset: tube)
                            ])
            tube.add_facts([
                             Fact.create(predicate: 'transferredFrom', object_asset: asset)
                           ])
          elsif f.predicate == 'SampleOutputVolume'
            tube.add_facts([
                             Fact.create(predicate: 'volume', object: f.object)
                           ])
          end
          f.destroy
        end
      end
    end

    def apply_symphony_facts_to_rack(rack)
      @doc.xpath('//SampleTrack').map do |sample_track|
        facts = %w(SampleCode SampleOutputPos SampleOutputVolume).map do |name|
          value = sample_track.at_xpath(name).text
          value = value.delete!(':') if name == 'SampleOutputPos'
          Fact.new(predicate: name,
                   object: value,
                   ns_predicate: Parsers::Symphony::SYMPHONY_NAMESPACE)
        end
        asset_location = facts.select do |f|
          f.predicate == 'SampleOutputPos' &&
            f.ns_predicate == Parsers::Symphony::SYMPHONY_NAMESPACE
        end.first.object

        asset = tube_at_location(rack, asset_location)
        if asset.nil?
          add_error("No tube present at location #{asset_location}. Transfer cannot be created.")
        end
        asset&.add_facts(facts)
      end
    end

    def add_error(msg)
      @error_messages.push(msg)
    end

    def self.parse(content, rack)
      @parser = Parsers::Symphony.new(content)
      @parser.apply_to_rack(rack)
      @parser.error_messages
    end

    def location_to_index(location)
      letter = location[0]
      num = location[1]
      (('A'..'F').find_index(location[0]) * 12) + (location[1].to_i - 1)
    end
  end
end
