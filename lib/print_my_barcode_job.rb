# frozen_string_literal: true

# Wraps a print job for Print My Barcode
# https://github.com/sanger/print_my_barcode
class PrintMyBarcodeJob
  # Custom class to indicate issues with Print My Barcode.
  # Use status code to pass on the same status code as print my barcode, defaults
  # to a 500.
  class PrintingError < StandardError
    attr_reader :status_code

    def initialize(message, status_code = 500)
      super(message)
      @status_code = status_code
    end
  end

  #
  # Build a new print job
  #
  # @param printer_name [String] The hostname of the printer to use (eg. d304bc)
  # @param label_template [String] The name of the label template to use as registered in Print my barcode
  # @param labels [Array<Hash>] Array of hashes containing label content
  #
  def initialize(printer_name:, label_template:, labels:)
    @printer_name = printer_name
    @label_template = label_template
    @labels = labels
  end

  #
  # Send the print job to print my barcode to trigger printing
  #
  def save
    v1? ? v1_request : v2_request
  end

  private

  #
  # Temporary method during transition. Determines if we are using the v1 or v2 API
  # based on the uri
  #
  # @return [Bool] Returns true if we are using the v1 api
  #
  def v1?
    pmb_uri.ends_with?('v1')
  end

  def pmb_uri
    Rails.configuration.pmb_uri
  end

  def v1_request
    PMB::PrintJob.new(
      printer_name: @printer_name,
      label_template_id: @label_template.external_id,
      labels: {
        body: v1_labels
      }
    ).save
  rescue JsonApiClient::Errors::ApiError => e
    raise PrintingError.new(e.message, e.env.response.status)
  end

  def v1_labels
    @labels.map { |label| { @label_template.label_name.to_sym => label } }
  end

  def v2_client
    Faraday.new(url: pmb_uri) do |faraday|
      faraday.request :json
      faraday.response :raise_error
    end
  end

  def v2_request
    v2_client.post('print_jobs', v2_body)
  rescue Faraday::Error => e
    raise PrintingError.new(e.message, e.response.fetch(:status, 500))
  end

  def v2_body
    { print_job: { printer_name: @printer_name, label_template_name: @label_template.name, labels: v2_labels } }
  end

  def v2_labels
    @labels.map { |label| label.merge(label_name: @label_template.label_name) }
  end
end
