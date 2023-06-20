import React from 'react'
import { HashFields, HiddenFieldTag } from 'react-rails-form-helpers'
class PrintersSelectionHidden extends React.Component {
  constructor(props) {
    super(props)
    this.nameForField = this.nameForField.bind(this)
  }
  nameForField(field) {
    return this.props.entityName + '[' + field + ']'
  }
  render() {
    return (
      <HashFields name={this.props.entityName}>
        <HiddenFieldTag
          name={this.nameForField('tube_printer_id')}
          value={this.props.selectedTubePrinter}
          className="tube_printer"
        />
        <HiddenFieldTag
          name={this.nameForField('plate_printer_id')}
          value={this.props.selectedPlatePrinter}
          className="plate_printer"
        />
      </HashFields>
    )
  }
}

export default PrintersSelectionHidden
