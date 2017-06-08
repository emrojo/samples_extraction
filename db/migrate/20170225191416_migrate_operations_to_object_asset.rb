# frozen_string_literal: true
class MigrateOperationsToObjectAsset < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do |_t|
      Operation.where('object is not null').each do |oper|
        obj_asset = Asset.find_by(uuid: oper.object)
        oper.update_attributes(object_asset_id: obj_asset.id) if obj_asset
      end
    end
  end
end
