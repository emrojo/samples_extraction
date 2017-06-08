# frozen_string_literal: true
class PrintJobsController < ApplicationController
  def printer_config
    { 'Tube' => 'd304bc', 'Plate' => 'd304bc' }
  end

  def create
    Class.new do
      include Printables::Group
      attr_reader :assets
      def initialize(assets)
        @assets = assets
      end
    end.new(@assets).print(printer_config, @current_user.username)
  end

  def set_assets
    @assets = params[:barcodes].map { |b| Asset.find_by(barcode: b) }
  end
end
