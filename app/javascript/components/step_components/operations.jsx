import React from 'react'
import Fact from '../asset_components/fact'

class Operations extends React.Component {
  constructor() {
    super()
    this.classForOperation = this.classForOperation.bind(this)
    this.renderOperationRow = this.renderOperationRow.bind(this)
  }
  classForOperation(operation) {
    if (operation.action_type == 'checkFacts') return 'glyphicon-search'
    if (operation.action_type == 'addFacts') return 'glyphicon-pencil'
    if (operation.action_type == 'removeFacts') return 'glyphicon-erase'
    if (operation.action_type == 'addAssets') return 'glyphicon-pencil'
    if (operation.action_type == 'removeAssets') return 'glyphicon-erase'
    if (operation.action_type == 'createAssets') return 'glyphicon-plus'
    if (operation.action_type == 'createAssetGroups') return 'glyphicon-plus'
    if (operation.action_type == 'deleteAssets') return 'glyphicon-minus'
    if (operation.action_type == 'deleteAssetGroups') return 'glyphicon-minus'
  }
  renderOperationRow(operation, index) {
    return (
      <tr key={index}>
        <td className="col-md-2">
          <span className={'glyphicon ' + this.classForOperation(operation)} aria-hidden="true"></span>
          {operation.action_type}
        </td>
        <td className="col-md-4">{operation.asset ? operation.asset.barcode || operation.asset.uuid : ''}</td>
        <td className="col-md-6" data-psd-component-class="AddFactToSearchbox">
          <Fact fact={operation} />
        </td>
      </tr>
    )
  }
  render() {
    if (this.props.operations.length == 0) {
      return (
        <tr>
          <td colSpan="7">No operations performed in this step.</td>
        </tr>
      )
    } else {
      return this.props.operations.map(this.renderOperationRow)
    }
  }
}

export default Operations
