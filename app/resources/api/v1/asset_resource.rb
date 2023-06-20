module Api
  module V1
    # JSON api information for a piece of labware in extraction (asset)
    class AssetResource < JSONAPI::Resource
      primary_key :uuid
      attributes :uuid,
                 :asset_type,
                 :barcode,
                 :sample_uuid,
                 :study_uuid,
                 :pipeline,
                 :library_type,
                 :estimate_of_gb_required,
                 :number_of_smrt_cells,
                 :cost_code,
                 :species,
                 :fields
      filters :barcode
    end
  end
end
