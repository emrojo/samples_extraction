# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create(barcode: '1', username: 'admin', role: 'administrator')

require 'support_n3'

SupportN3.parse_file('db/workflows/reracking.n3')

reracking_activity_type = ActivityType.last
kit_type = KitType.create(name: 'Re-Racking', activity_type: reracking_activity_type)
kit = Kit.create(barcode: '9999', kit_type: kit_type)
instrument = Instrument.create(barcode: '9999', name: 'Re-Racking')
instrument.activity_types << reracking_activity_type

SupportN3.parse_file('db/workflows/qiacube.n3')

activity_type = ActivityType.last

kt = KitType.create(name: 'qiacube', activity_type: activity_type)

Kit.create(barcode: '1234', kit_type: kt)

Printer.create(name: 'd304bc', printer_type: 'Plate', default_printer: true)
Printer.create(name: 'e367bc', printer_type: 'Tube', default_printer: true)

instrument.activity_types << activity_type

runners =
  [
    ['[DEMO] Create 12 tubes', 'create_12_tubes.rb'],
    ['[DEMO] Generate plate layout file', 'create_layout.rb'],
    [
      'Aliquot type inference',
      'aliquot_type_inference.rb',
      '
    {
      ?p :contains ?q .
      ?q :aliquotType ?_aliquot .
    }=>{}.
    '
    ],
    ['Print barcodes', 'print_barcodes.rb'],
    [
      'Purpose name inference',
      'purpose_name_inference.rb',
      '
    {
      ?p :contains ?q .
      ?q :aliquotType ?_aliquot .
    }=>{}.
    '
    ],
    [
      'Rack Layout',
      'rack_layout.rb',
      '
    {
      ?p :contains ?q .
      ?p :a :TubeRack .
      ?q :a :File .
    }=>{}.
    '
    ],
    [
      'Rack Layout creating tubes',
      'StepPlanner::RackLayoutCreatingTubes',
      '
    {
      ?p :contains ?q .
      ?p :a :TubeRack .
      ?q :a :File .
    }=>{}.
    '
    ],
    [
      'Study name inference',
      'study_name_inference.rb',
      '
    {
      ?p :contains ?q .
      ?q :study_name ?_aliquot .
    }=>{}.
    '
    ],
    [
      'Transfer plate to plate',
      'transfer_plate_to_plate.rb',
      '

    {
      ?p :a :Plate .
      ?q :a :Plate .
      ?p :transfer ?q .
      ?p :contains ?tube . } => {} .
    '
    ],
    [
      'Transfer samples',
      'transfer_samples.rb',
      '
    { ?p :transfer ?q .}=> {}.
    '
    ],
    [
      'Transfer tubes to tube rack by position',
      'transfer_tubes_to_tube_rack_by_position.rb',
      '
    {
      ?p :a :TubeRack .
      ?q :a :Tube .
    }=>{}.
    '
    ],
    [
      'Update Sequencescape',
      'update_sequencescape.rb',
      '
    { ?p :a :TubeRack .}=>{}.
    '
    ]
  ].map { |l| StepType.create(name: l[0], step_action: l[1], n3_definition: l[2]) }

# reracking_activity_type.step_types << runners
