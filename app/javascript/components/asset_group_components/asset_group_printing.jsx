import React from 'react'
import { FormFor } from 'react-rails-form-helpers'
import { getCsrfToken } from '../lib/uploader_utils'

import PrintersSelection from '../activity_components/printers_selection'

const findName = (options, value) => {
  const [defaultName, _defaultId] = options.find(([_name, id]) => id === value) || options[0]
  return defaultName
}
const findDefaultName = ({ optionsData, defaultValue }) => findName(optionsData, defaultValue)
/**
  assetGroup: {
    printUrl<String>: The target url for the form
  },
  platePrinter: {
    defaultValue<Numeric>: default printer id,
    optionsData: [
      [
        printer name <String>,
        printer id <Numeric>
      ]
    ]
  },
  tubePrinter: {
    defaultValue<Numeric>: default printer id,
    optionsData: [
      [
        printer name <String>,
        printer id <Numeric>
      ]
    ]
  },
  onMessage: Error message handler function
**/
class AssetGroupPrinting extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      Tube: findDefaultName(this.props.tubePrinter),
      Plate: findDefaultName(this.props.platePrinter),
    }

    // Bind Events
    // https://reactjs.org/docs/faq-functions.html#how-do-i-bind-a-function-to-a-component-instance
    this.onChangeTubePrinter = this.onChangeTubePrinter.bind(this)
    this.onChangePlatePrinter = this.onChangePlatePrinter.bind(this)
    this.onSubmit = this.onSubmit.bind(this)
  }
  onChangeTubePrinter(e) {
    this.setState({ Tube: findName(this.props.tubePrinter.optionsData, e.target.value) })
  }
  onChangePlatePrinter(e) {
    this.setState({ Plate: findName(this.props.platePrinter.optionsData, e.target.value) })
  }
  onSubmit(e) {
    e.preventDefault()
    window
      .fetch(this.props.assetGroup.printUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': getCsrfToken(),
        },
        body: JSON.stringify({ printerConfig: this.state }),
      })
      .then((response) => response.json())
      .then((result) => this.props.onMessage({ type: result.success ? 'success' : 'danger', msg: result.message }))
      .catch((error) => this.props.onMessage({ type: 'danger', msg: error.toString() }))
  }
  render() {
    if (this.props.assetGroup.assets.length > 0) {
      return (
        <FormFor url={this.props.assetGroup.printUrl} className="print_asset_group row" onSubmit={this.onSubmit}>
          <div className="col-xs-10">
            <PrintersSelection
              tubePrinter={this.props.tubePrinter}
              platePrinter={this.props.platePrinter}
              onChangeTubePrinter={this.onChangeTubePrinter}
              onChangePlatePrinter={this.onChangePlatePrinter}
            />
          </div>
          <div className="col-xs-2">
            <label className="col-xs-12">&nbsp;</label>
            <button type="submit" className="btn btn-default">
              Print
            </button>
          </div>
        </FormFor>
      )
    } else {
      return 'No assets to print'
    }
  }
}

export default AssetGroupPrinting
