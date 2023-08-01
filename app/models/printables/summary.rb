# frozen_string_literal: true

module Printables
  # Simple helper class to track printing summaries
  class Summary
    def initialize
      @print_counts = Hash.new { |h, i| h[i] = 0 }
    end

    def add_labels(printer, count)
      @print_counts[printer] += count
    end

    def to_s
      @print_counts.map { |printer, count| "#{count} labels sent to #{printer}" }.to_sentence
    end
  end
end
