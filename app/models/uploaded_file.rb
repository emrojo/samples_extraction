require 'csv'
require 'fact_changes'

class UploadedFile < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :asset

  def step
    @step ||= Step.new(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
  end

  def file_type(content_type)
    return 'XML' if content_type == 'text/xml'
    return 'CSV' if content_type == 'text/csv'

    return 'Unknown'
  end

  def build_asset(params)
    unless asset
      update(asset: Asset.create)
      FactChanges
        .new
        .tap do |updates|
          updates.add(asset, 'a', 'File')
          updates.add(asset, 'filename', filename)
          updates.add(asset, 'fileType', file_type(params[:content_type]))
          updates.add(asset, 'contents', asset)
        end
        .apply(step)
    end
    asset.touch
    asset
  end
end
