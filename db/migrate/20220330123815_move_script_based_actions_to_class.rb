# frozen_string_literal: true

# We've replaces some scripts with simple classes for performance reasons. Not only
# does this avoid us needing to spin up a new process per job, but also avoids the need to
# go through a round trip of serialization and deserialization, which inccurs a further
# penalty when it results in additional trips to the database
class MoveScriptBasedActionsToClass < ActiveRecord::Migration[5.2]
  CONVERTED_CLASS_ACTIONS = {
    'move_barcodes_from_tube_rack_to_plate.rb' => 'StepPlanner::MoveBarcodesFromTubeRackToPlate',
    'rack_layout_creating_tubes.rb' => 'StepPlanner::RackLayoutCreatingTubes'
  }.freeze

  def up
    CONVERTED_CLASS_ACTIONS.each { |from, to| convert(from, to) }
  end

  def down
    CONVERTED_CLASS_ACTIONS.each { |from, to| convert(to, from) }
  end

  private

  def convert(from, to)
    say "Converting #{from} to #{to}"

    # We update in bulk to improve performance, and avoid coupling to future validation changes
    StepType.where(step_action: from).update_all(step_action: to) # rubocop:disable Rails/SkipsModelValidations
  end
end
