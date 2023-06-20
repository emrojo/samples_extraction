import React from 'react'

import { LabelTag, SelectTag } from 'react-rails-form-helpers'

class PrintersSelection extends React.Component {
  renderOptions(optsData, defaultValue) {
    return optsData.map((pos, val) => {
      return (
        <option key={pos[1]} value={pos[1]}>
          {pos[0]}
        </option>
      )
    })
  }
  render() {
    return (
      <div className="row">
        <div className="form-group col-xs-6">
          <LabelTag htmlFor="tube_printer_select">Tube Printer</LabelTag>
          <SelectTag
            name="tube_printer_select"
            className="form-control"
            defaultValue={this.props.tubePrinter.defaultValue}
            onChange={this.props.onChangeTubePrinter}
          >
            {this.renderOptions(this.props.tubePrinter.optionsData)}
          </SelectTag>
        </div>
        <div className="form-group col-xs-6">
          <LabelTag htmlFor="plate_printer_select">Plate Printer</LabelTag>
          <SelectTag
            name="plate_printer_select"
            className="form-control"
            defaultValue={this.props.platePrinter.defaultValue}
            onChange={this.props.onChangePlatePrinter}
          >
            {this.renderOptions(this.props.platePrinter.optionsData)}
          </SelectTag>
        </div>
      </div>
    )
  }
}

export default PrintersSelection
