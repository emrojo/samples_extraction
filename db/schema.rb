# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_04_01_124332) do
  create_table 'actions', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'action_type', null: false
    t.integer 'step_type_id'
    t.integer 'subject_condition_group_id'
    t.string 'predicate', null: false
    t.string 'object'
    t.integer 'object_condition_group_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['object_condition_group_id'], name: 'index_actions_on_object_condition_group_id'
    t.index ['step_type_id'], name: 'index_actions_on_step_type_id'
    t.index ['subject_condition_group_id'], name: 'index_actions_on_subject_condition_group_id'
  end

  create_table 'activities', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'activity_type_id'
    t.integer 'instrument_id'
    t.integer 'asset_group_id'
    t.integer 'kit_id'
    t.datetime 'completed_at'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer 'active_step_id'
    t.string 'state'
    t.index ['active_step_id'], name: 'index_activities_on_active_step_id'
    t.index ['activity_type_id'], name: 'index_activities_on_activity_type_id'
    t.index ['asset_group_id'], name: 'index_activities_on_asset_group_id'
    t.index ['instrument_id'], name: 'index_activities_on_instrument_id'
    t.index ['kit_id'], name: 'index_activities_on_kit_id'
  end

  create_table 'activity_type_compatibilities',
               id: :integer,
               force: :cascade,
               options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'asset_id'
    t.integer 'activity_type_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['activity_type_id'], name: 'index_activity_type_compatibilities_on_activity_type_id'
    t.index ['asset_id'], name: 'index_activity_type_compatibilities_on_asset_id'
  end

  create_table 'activity_type_step_types',
               id: :integer,
               force: :cascade,
               options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'activity_type_id'
    t.integer 'step_type_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['activity_type_id'], name: 'index_activity_type_step_types_on_activity_type_id'
    t.index ['step_type_id'], name: 'index_activity_type_step_types_on_step_type_id'
  end

  create_table 'activity_types', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name'
    t.integer 'superceded_by_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['superceded_by_id'], name: 'index_activity_types_on_superceded_by_id'
  end

  create_table 'activity_types_instruments',
               id: :integer,
               force: :cascade,
               options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'instrument_id'
    t.integer 'activity_type_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['activity_type_id'], name: 'index_activity_types_instruments_on_activity_type_id'
    t.index ['instrument_id'], name: 'index_activity_types_instruments_on_instrument_id'
  end

  create_table 'asset_groups', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'activity_owner_id'
    t.integer 'condition_group_id'
    t.string 'name'
    t.string 'uuid'
  end

  create_table 'asset_groups_assets',
               id: :integer,
               force: :cascade,
               options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'asset_id'
    t.integer 'asset_group_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['asset_group_id'], name: 'index_asset_groups_assets_on_asset_group_id'
    t.index ['asset_id'], name: 'index_asset_groups_assets_on_asset_id'
  end

  create_table 'assets', id: :integer, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1', force: :cascade do |t|
    t.string 'uuid', null: false
    t.string 'barcode'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'facts_count'
    t.string 'remote_digest'
    t.index ['barcode'], name: 'index_assets_on_barcode'
    t.index ['uuid'], name: 'index_assets_on_uuid'
  end

  create_table 'condition_groups',
               id: :integer,
               force: :cascade,
               options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name'
    t.boolean 'keep_selected', default: true
    t.integer 'step_type_id'
    t.integer 'cardinality'
    t.index ['step_type_id'], name: 'index_condition_groups_on_step_type_id'
  end

  create_table 'conditions', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'condition_group_id'
    t.string 'predicate', null: false
    t.string 'object'
    t.integer 'object_condition_group_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['condition_group_id'], name: 'index_conditions_on_condition_group_id'
    t.index ['object_condition_group_id'], name: 'index_conditions_on_object_condition_group_id'
  end

  create_table 'delayed_jobs', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'priority', default: 0, null: false
    t.integer 'attempts', default: 0, null: false
    t.text 'handler', limit: 4_294_967_295, null: false
    t.text 'last_error', limit: 4_294_967_295
    t.datetime 'run_at'
    t.datetime 'locked_at'
    t.datetime 'failed_at'
    t.string 'locked_by'
    t.string 'queue'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index %w[priority run_at], name: 'delayed_jobs_priority'
  end

  create_table 'facts', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'asset_id'
    t.string 'predicate', null: false
    t.string 'object'
    t.boolean 'literal', default: true, null: false
    t.integer 'object_asset_id'
    t.integer 'to_add_by'
    t.integer 'to_remove_by'
    t.boolean 'up_to_date', default: false, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'position'
    t.string 'ns_predicate'
    t.boolean 'is_remote?', default: false
    t.index ['asset_id'], name: 'index_facts_on_asset_id'
    t.index ['object_asset_id'], name: 'index_facts_on_object_asset_id'
  end

  create_table 'instruments', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'barcode'
    t.string 'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'kit_types', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name'
    t.integer 'activity_type_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'abbreviation'
    t.index ['activity_type_id'], name: 'index_kit_types_on_activity_type_id'
  end

  create_table 'kits', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'barcode', null: false
    t.integer 'max_num_reactions'
    t.integer 'num_reactions_performed'
    t.integer 'kit_type_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['kit_type_id'], name: 'index_kits_on_kit_type_id'
  end

  create_table 'label_templates', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name', null: false
    t.string 'template_type'
    t.integer 'external_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'operations', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'action_id'
    t.integer 'step_id'
    t.integer 'asset_id'
    t.string 'predicate'
    t.string 'object'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string 'action_type'
    t.integer 'object_asset_id'
    t.boolean 'cancelled?', default: false
    t.index ['action_id'], name: 'index_operations_on_action_id'
    t.index ['asset_id'], name: 'index_operations_on_asset_id'
    t.index ['step_id'], name: 'index_operations_on_step_id'
  end

  create_table 'printers', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name', null: false
    t.string 'printer_type'
    t.boolean 'default_printer', default: false, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'sessions', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'session_id', null: false
    t.text 'data'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['session_id'], name: 'index_sessions_on_session_id', unique: true
    t.index ['updated_at'], name: 'index_sessions_on_updated_at'
  end

  create_table 'step_messages', force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
    t.integer 'step_id', null: false
    t.text 'content', limit: 4_294_967_295
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['step_id'], name: 'index_step_messages_on_step_id'
  end

  create_table 'step_types', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'name'
    t.string 'step_template'
    t.binary 'n3_definition'
    t.integer 'superceded_by_id'
    t.boolean 'for_reasoning', default: false, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'connect_by'
    t.string 'step_action'
    t.integer 'priority', default: 0, null: false
    t.index ['superceded_by_id'], name: 'index_step_types_on_superceded_by_id'
  end

  create_table 'steps', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'step_type_id'
    t.integer 'user_id'
    t.date 'completion_date'
    t.integer 'activity_id'
    t.integer 'asset_group_id'
    t.integer 'created_asset_group_id'
    t.boolean 'in_progress?', default: false
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string 'state'
    t.integer 'superceded_by_id'
    t.text 'output', limit: 4_294_967_295
    t.integer 'next_step_id'
    t.string 'sti_type'
    t.text 'printer_config'
    t.datetime 'started_at'
    t.datetime 'finished_at'
    t.integer 'job_id'
    t.index ['activity_id'], name: 'index_steps_on_activity_id'
    t.index ['asset_group_id'], name: 'index_steps_on_asset_group_id'
    t.index ['created_asset_group_id'], name: 'index_steps_on_created_asset_group_id'
    t.index ['next_step_id'], name: 'index_steps_on_next_step_id'
    t.index ['step_type_id'], name: 'index_steps_on_step_type_id'
    t.index ['user_id'], name: 'index_steps_on_user_id'
  end

  create_table 'uploaded_files', force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
    t.integer 'asset_id'
    t.binary 'data', limit: 16_777_215
    t.string 'filename'
    t.string 'content_type'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['asset_id'], name: 'index_uploaded_files_on_asset_id'
  end

  create_table 'uploads', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'step_id'
    t.integer 'activity_id'
    t.binary 'data', limit: 16_777_215
    t.string 'filename'
    t.string 'content_type'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['activity_id'], name: 'index_uploads_on_activity_id'
    t.index ['step_id'], name: 'index_uploads_on_step_id'
  end

  create_table 'users', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.string 'login'
    t.string 'password'
    t.string 'barcode'
    t.string 'username'
    t.string 'fullname'
    t.string 'token'
    t.string 'role', default: 'operator'
    t.integer 'tube_printer_id'
    t.integer 'plate_printer_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['plate_printer_id'], name: 'index_users_on_plate_printer_id'
    t.index ['tube_printer_id'], name: 'index_users_on_tube_printer_id'
  end

  create_table 'work_orders', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=latin1' do |t|
    t.integer 'work_order_id'
    t.integer 'activity_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['activity_id'], name: 'index_work_orders_on_activity_id'
    t.index ['work_order_id'], name: 'index_work_orders_on_work_order_id'
  end

  add_foreign_key 'actions', 'step_types'
  add_foreign_key 'activities', 'activity_types'
  add_foreign_key 'activities', 'asset_groups'
  add_foreign_key 'activities', 'instruments'
  add_foreign_key 'activities', 'kits'
  add_foreign_key 'activity_type_compatibilities', 'activity_types'
  add_foreign_key 'activity_type_compatibilities', 'assets'
  add_foreign_key 'activity_type_step_types', 'activity_types'
  add_foreign_key 'activity_type_step_types', 'step_types'
  add_foreign_key 'activity_types_instruments', 'activity_types'
  add_foreign_key 'activity_types_instruments', 'instruments'
  add_foreign_key 'asset_groups_assets', 'asset_groups'
  add_foreign_key 'asset_groups_assets', 'assets'
  add_foreign_key 'condition_groups', 'step_types'
  add_foreign_key 'conditions', 'condition_groups'
  add_foreign_key 'facts', 'assets'
  add_foreign_key 'kit_types', 'activity_types'
  add_foreign_key 'kits', 'kit_types'
  add_foreign_key 'operations', 'actions'
  add_foreign_key 'operations', 'assets'
  add_foreign_key 'operations', 'steps'
  add_foreign_key 'steps', 'activities'
  add_foreign_key 'steps', 'asset_groups'
  add_foreign_key 'steps', 'step_types'
  add_foreign_key 'steps', 'users'
  add_foreign_key 'uploads', 'activities'
  add_foreign_key 'uploads', 'steps'
  add_foreign_key 'work_orders', 'activities'
end
