require './lib/label_template_setup'

LabelTemplateSetup.register_label_type("Plate", {
                                         type: "label_types",
                                         attributes: {
                                           feed_value: "008",
                                           fine_adjustment: "04",
                                           pitch_length: "0110",
                                           print_width: "0920",
                                           print_length: "0080",
                                           name: "Plate"
                                         }
                                       })
