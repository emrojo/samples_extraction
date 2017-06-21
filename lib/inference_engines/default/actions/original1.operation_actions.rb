# frozen_string_literal: true
module InferenceEngines
  module Default
    module Actions
      module OperationActions
        def create_operation(asset, fact)
          Operation.create!(action: action, step: step,
                            asset: asset, predicate: fact.predicate, object: fact.object, object_asset: fact.object_asset)
        end
      end
    end
  end
end
