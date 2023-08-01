class ChangesController < ApplicationController # rubocop:todo Style/Documentation
  def create
    @step = Step.create(state: 'running')
    json = params_changes.to_json
    @updates = FactChanges.new(json)
    @step.update(state: 'complete') if @updates.apply(@step)
    facts_updated = @updates.assets_updated.map(&:facts)
    render json: {
             step: @step,
             assets: @updates.assets_updated,
             facts: facts_updated,
             dataAssetDisplay: facts_updated.map { |facts| helpers.data_asset_display(facts) }
           }
  end

  private

  def params_changes
    params.require(:changes).permit!
  end
end
