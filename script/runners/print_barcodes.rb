# Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

class PrintBarcodes # rubocop:todo Style/Documentation
  attr_reader :asset_group, :step

  def initialize(params)
    @asset_group = params[:asset_group]
    @step = params[:step]
  end

  # %Q{
  #   {
  #     ?asset :is :readyForPrint .
  #     ?username :a :CurrentUser .
  #     ?tubePrinter :a :TubePrinter .
  #   } => {
  #     :step :action :print .
  #     :step :firstArg ?tubePrinter .
  #     :step :secondArg ?username .
  #     :step :removeFacts { ?asset :is :readyForPrint . }.
  #   } .
  # }

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('is', 'readyForPrint').count > 0
  end

  def process
    FactChanges.new.tap do |updates|
      if assets_compatible_with_step_type
        asset_group.assets.each do |asset|
          asset.print(printer_config)

          # Do not print again unless the step fails
          updates.remove(Fact.where(asset: asset, predicate: 'is', object: 'readyForPrint'))
        end
      end
    end
  end
end

return unless ARGV.any? { |s| s.match('.json') }

args = ARGV[0]
asset_group_id = args.match(/(\d*)\.json/)[1]
asset_group = AssetGroup.find(asset_group_id)
puts PrintBarcodes.new(asset_group: asset_group).process.to_json
