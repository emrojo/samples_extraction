class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  has_many :uploads
  has_many :operations

  after_create :execute_actions

  def classify_assets
    perform_list = []
    step_type.actions.each do |r|
      if r.subject_condition_group.cardinality == 1
        perform_list.push([nil, r])
      else
        asset_group.assets.each do |asset|
          if r.subject_condition_group.compatible_with?(asset)
            perform_list.push([asset, r])
          end
        end
      end
    end
    perform_list.sort do |a,b|
      if a[1].action_type=='createAsset'
        -1
      elsif b[1].action_type=='createAsset'
        1
      else
        a[1].action_type <=> b[1].action_type
      end
    end
  end

  def execute_actions
    created_assets = {}
    classify_assets.each do |asset, r|
      r.execute(self, asset, created_assets)
    end
  end

end