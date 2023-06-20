module AssetsHelper # rubocop:todo Style/Documentation
  def condition_groups_init_for_asset(asset)
    obj = {}
    obj[asset.barcode] = { template: 'templates/asset_facts' }
    obj[asset.barcode][:facts] =
      asset.facts.map do |fact|
        {
          cssClasses: '',
          name: asset.uuid,
          actionType: 'createAsset',
          predicate: fact.predicate,
          object_reference: fact.object_asset_id,
          object_label: fact.object_label,
          object: asset.object_value(fact)
        }
      end

    obj
  end
end
