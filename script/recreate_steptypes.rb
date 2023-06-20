[
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
].map do |l|
  s = StepType.find_by(name: l[0])
  s2 = StepType.create(name: l[0], step_action: l[1], for_reasoning: true, n3_definition: l[2])
  s.deprecate_with(s)
end
