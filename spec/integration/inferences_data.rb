def inferences_data
  [
    {
      it: 'keeps elements the way they are when there is no changes',
      rule: ' { ?x :t ?_y .} => { :step :addFacts {?x :t ?_y .}. }. ',
      inputs: ' :a :t "1" . ',
      outputs: ' :a :t "1" .'
    },
    {
      it: 'keeps elements the way they are when there is no changes',
      rule: ' { ?x :t ?_y .} => { :step :addFacts {?x :t ?_y .}. }. ',
      inputs: ' :a :t "1" . :b :t "2".',
      outputs: ' :a :t "1" . :b :t "2".'
    },
    {
      it: 'keeps elements the way they are when there is no changes',
      rule: ' { ?x :relation_r ?_y .} => { :step :addFacts { ?x :relation_r ?_y . }. }. ',
      inputs: ' :a :relation_r """1""" . :b :relation_r :a .',
      outputs: ' :a :relation_r """1""" . :b :relation_r :a .'
    },
    {
      it: 'relates elements with wildcard and with literal',
      rule:
        '
        {
          ?x :s """1""" .
          ?y :t ?_val .
        } => {
          :step :addFacts {?x :val ?_val }.
        }

    ',
      inputs:
        '
        :tube1 :s """1""" .
        :tube2 :t """2""" .
        :tube3 :s """1""" .
        :tube4 :t """2""" .

    ',
      outputs:
        '
        :tube1 :s """1""" .
        :tube1 :val """2""" .
        :tube2 :t """2""" .

        :tube3 :s """1""" .
        :tube3 :val """2""" .
        :tube4 :t """2""" .
  '
    },
    {
      it: 'relates elements with wildcard',
      rule:
        '
        {
          ?x :t ?_pos .
          ?y :t ?_pos .
        } => {
          :step :addFacts {?x :relates_with ?y }.
        }
    ',
      inputs:
        '
        :tube1 :t """1""" .
        :tube2 :t """2""" .
        :tube3 :t """1""" .
        :tube4 :t """2""" .

    ',
      outputs:
        '
        :tube1 :t """1""" .
        :tube2 :t """2""" .
        :tube3 :t """1""" .
        :tube4 :t """2""" .
        :tube1 :relates_with :tube3 .
        :tube3 :relates_with :tube1 .
        :tube2 :relates_with :tube4 .
        :tube4 :relates_with :tube2 .
        :tube1 :relates_with :tube1 .
        :tube2 :relates_with :tube2 .
        :tube3 :relates_with :tube3 .
        :tube4 :relates_with :tube4 .
  '
    },
    {
      it: 'relates elements with relation',
      tags: :testing,
      rule:
        '
        {
          ?x :a "TubeA" .
          ?x :transfer ?y .
          ?y :a "TubeB" .
        } => {
          :step :addFacts { ?y :transferredFrom ?x . }.
        }
    ',
      inputs:
        '
        :tube1 :a "TubeA" .
        :tube1 :transfer :tube2 .
        :tube2 :a "TubeB" .

    ',
      outputs:
        '
        :tube1 :a """TubeA""" .
        :tube2 :a """TubeB""" .

        :tube1 :transfer :tube2 .
        :tube2 :transferredFrom :tube1 .
  '
    },
    {
      it: 'set the value if the destination does not have the value',
      unless: :cwm_engine?,
      rule:
        '
    {
      ?x :a :Tube .
      ?y :a :Tube .
      ?x :transfer ?y .
      ?x :aliquotType ?_aliquot .
      ?y :hasNotPredicate :aliquotType .
    } => {
      :step :addFacts {?y :aliquotType ?_aliquot .}.
    }.
  ',
      inputs:
        '
        :tube1 :a :Tube .
        :tube1 :transfer :tube2 .
        :tube2 :a :Tube .
        :tube1 :aliquotType "DNA" .
  ',
      outputs:
        '
        :tube1 :a :Tube .
        :tube1 :transfer :tube2 .
        :tube2 :a :Tube .
        :tube1 :aliquotType "DNA" .
        :tube2 :aliquotType "DNA" .
  '
    },
    {
      it: 'only set the value if the destination does not have the value already',
      rule:
        '
    {
      ?x :a :Tube .
      ?y :a :Tube .
      ?x :transfer ?y .
      ?x :aliquotType ?_aliquot .
      ?y :hasNotPredicate :aliquotType .
    } => {
      :step :addFacts {?y :aliquotType ?_aliquot .}.
    }.
  ',
      inputs:
        '
        :tube1 :a :Tube .
        :tube1 :transfer :tube2 .
        :tube2 :a :Tube .
        :tube1 :aliquotType """DNA""" .
        :tube2 :aliquotType """RNA""" .
  ',
      outputs:
        '
        :tube1 :a :Tube .
        :tube1 :transfer :tube2 .
        :tube2 :a :Tube .
        :tube1 :aliquotType """DNA""" .
        :tube2 :aliquotType """RNA""" .
  '
    },
    {
      it: 'transfer between plates',
      unless: :cwm_engine?,
      rule:
        '
    {
      ?plate :a :Plate .
      ?plate2 :a :Plate .
      ?plate :transfer ?plate2 .

      ?plate :contains ?tube1 .
      ?tube1 :a :Tube .
      ?plate2 :contains ?tube2 .
      ?tube2 :a :Tube .

      ?tube1 :location ?_location .
      ?tube2 :location ?_location .
      ?tube1 log:notEqualTo ?tube2 .
    } => {
      :step :addFacts {?tube1 :transfer ?tube2 .}.
    }.
  ',
      inputs:
        '
      :plate1 :a :Plate .
      :plate2 :a :Plate .
      :tube1 :a :Tube .
      :tube2 :a :Tube .
      :tube3 :a :Tube .

      :plate1 :transfer :plate2 .
      :plate1 :contains :tube1.
      :plate2 :contains :tube2.
      :tube1 :location "C10" .
      :tube2 :location "C10" .
      :tube3 :location "D9" .
      :plate1 :contains :tube3 .
  ',
      outputs:
        '
      :plate1 :a :Plate .
      :plate2 :a :Plate .
      :tube1 :a :Tube .
      :tube2 :a :Tube .
      :tube3 :a :Tube .

      :plate1 :transfer :plate2 .
      :plate1 :contains :tube1.
      :plate2 :contains :tube2.
      :tube1 :location "C10" .
      :tube2 :location "C10" .
      :tube3 :location "D9" .
      :plate1 :contains :tube3 .

      :tube1 :transfer :tube2 .
  '
    },
    {
      xit: 'perform math operations',
      rule:
        '
    {
      ?plate :a :Plate .

      ?plate :contains ?well .
      ?well :a :Well .
      ?well :contains ?aliquot .
      ?aliquot :a :Aliquot .
      ?aliquot :currentVolume ?_volume .
      (?_volume 10) math:sum ?_newVolume .
    } => {
      :step :removeFacts {?aliquot :currentVolume ?_volume .}.
      :step :addFacts {?aliquot :currentVolume ?newVolume .}.
    }.
  ',
      inputs:
        '
      :plate1 :a """Plate""" .
      :well1 :a """Well""" .

      :well1 :contains :aliquot1 .
      :aliquot1 :a :Aliquot .
      :aliquot1 :currentVolume """20""".

  ',
      outputs:
        '
      :plate1 :a """Plate""" .
      :well1 :a """Well""" .

      :well1 :contains :aliquot1 .
      :aliquot1 :a :Aliquot .
      :aliquot1 :currentVolume """30""".
  '
    },
    {
      it: 'moves the value of a wildcard using a relation between two cgroups',
      rule:
        '
      {
        ?tube :is "Tube" .
        ?tube :location ?_position .
        ?rack :is "Rack" .
        ?rack :position ?_position .
        ?rack :contains ?tube .
        ?rack :relates ?tube .
      } => {
        :step :addFacts {?rack :is "TubeRack" .} .
        :step :addFacts {?rack :location ?_position .} .
      }
    ',
      inputs:
        '
      :tube1 :is "Tube" , :Full ; :location "1".
      :tube2 :is "Tube" , :Full ; :location "2".
      :tube3 :is "Tube" , :Full ; :location "3".
      :tube4 :is "Tube" , :Full ; :location "4".
      :tube5 :is "Tube" , :Full ; :location "5".
      :tube6 :is "Tube" , :Full ; :location "6".
      :tube7 :is "Tube" , :Full ; :location "7".

      :rack1 :is "Rack" , :Full ; :contains :tube1 ; :position "1" ; :relates :tube1 .
      :rack2 :is "Rack" , :Full ; :contains :tube2 ; :position "2" ; :relates :tube2 .
      :rack3 :is "Rack" , :Full ; :contains :tube3 ; :position "3" ; :relates :tube3 .
      :rack4 :is "Rack" , :Full ; :contains :tube4 ; :position "4" ; :relates :tube4 .
      :rack5 :is "Rack" , :Full ; :contains :tube5 ; :position "5" ; :relates :tube5 .
    ',
      outputs:
        '
      :tube1 :is "Tube" , :Full ; :location "1".
      :tube2 :is "Tube" , :Full ; :location "2".
      :tube3 :is "Tube" , :Full ; :location "3".
      :tube4 :is "Tube" , :Full ; :location "4".
      :tube5 :is "Tube" , :Full ; :location "5".
      :tube6 :is "Tube" , :Full ; :location "6".
      :tube7 :is "Tube" , :Full ; :location "7".

      :rack1 :is "Rack" , "TubeRack" , :Full ; :contains :tube1 ; :position "1" ; :relates :tube1 ; :location "1" .
      :rack2 :is "Rack" , "TubeRack" , :Full ; :contains :tube2 ; :position "2" ; :relates :tube2 ; :location "2" .
      :rack3 :is "Rack" , "TubeRack" , :Full ; :contains :tube3 ; :position "3" ; :relates :tube3 ; :location "3" .
      :rack4 :is "Rack" , "TubeRack" , :Full ; :contains :tube4 ; :position "4" ; :relates :tube4 ; :location "4" .
      :rack5 :is "Rack" , "TubeRack" , :Full ; :contains :tube5 ; :position "5" ; :relates :tube5 ; :location "5" .
    '
    },
    {
      it: 'Bug 1: Not transferring tube contents to tube rack',
      rule:
        '
{
  ?tuberack :a :TubeRack .
  ?tuberack :layout :Complete .
  ?tube :a :Tube .
  ?tube :sanger_sample_id ?_sample .
} => { :step :addFacts {?tube :transferToTubeRackByPosition ?tuberack . } . } .
      ',
      inputs:
        '
:tube :a "Tube" .
:tube :aliquotType "RNA" .
:tube :is "Used" .
:tube :sanger_sample_id "2STDY9" .
:tube :sample_id "2STDY9" .
:tube :transferredFrom :tube0 .
:tube :creates :tubeRack .
:tubeRack :a "TubeRack" .
:tubeRack :barcodeType "NoBarcode" .
:tubeRack :createdFrom :tube .
:tubeRack :contains :tube2 .
:tubeRack :contains :tube3 .
:tubeRack :layout "Complete" .    ',
      outputs:
        '
:tube :transferToTubeRackByPosition :tubeRack .
:tube :a "Tube" .
:tube :aliquotType "RNA" .
:tube :is "Used" .
:tube :sanger_sample_id "2STDY9" .
:tube :sample_id "2STDY9" .
:tube :transferredFrom :tube0 .
:tube :creates :tubeRack .
:tubeRack :a "TubeRack" .
:tubeRack :barcodeType "NoBarcode" .
:tubeRack :createdFrom :tube .
:tubeRack :contains :tube2 .
:tubeRack :contains :tube3 .
:tubeRack :layout "Complete" .
    '
    },
    {
      it: 'creates new assets from scratch',
      rule:
        '
      {?p :maxCardinality "1" .} => {
        :step :createAsset {?p :a :Tube . ?p :uuid "tube" .}
        } .
      ',
      inputs: '',
      outputs:
        '
      :tube :a :Tube .
      :tube :uuid "tube" .
    '
    }
  ]
end
