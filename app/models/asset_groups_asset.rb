# Asset belonging to an asset group.
# Assets can belong to several asset groups at the same time
# (many to many relation)
class AssetGroupsAsset < ApplicationRecord
  belongs_to :asset
  belongs_to :asset_group
end
