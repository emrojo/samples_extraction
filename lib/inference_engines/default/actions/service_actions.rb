# frozen_string_literal: true
module InferenceEngines
  module Default
    module Actions
      module ServiceActions
        def update_service
          asset.update_attributes(mark_to_update: true)
        end
      end
    end
  end
end
