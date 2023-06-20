import React from 'react'
class BarcodeReader extends React.Component {
  renderIcon() {
    if (this.props.disabledBarcodesInput) {
      return (
        <div className="spinner">
          <span className="glyphicon glyphicon-refresh fast-right-spinner"></span>
        </div>
      )
    } else {
      return <span className="glyphicon glyphicon-arrow-down"></span>
    }
  }
  render() {
    return (
      <div data-turbolinks="false">
        <label htmlFor="asset_group_add_barcode" className="control-label">
          Add a barcode
        </label>
        <div className="input-group">
          <input
            ref={(input) => {
              this.nameInput = input
            }}
            value={this.props.barcodesInputText}
            onChange={this.props.handleChange}
            disabled={this.props.disabledBarcodesInput || this.props.activityRunning}
            autoComplete="off"
            name="asset_group[assets]"
            className="form-control"
            type="text"
            placeholder="Scan a barcode"
          />
          <span className="input-group-btn">
            <button
              disabled={this.props.disabledBarcodesInput || this.props.activityRunning}
              type="submit"
              className="btn btn-default barcode-send"
              title="Send barcode"
            >
              {this.renderIcon()}
            </button>
          </span>
        </div>
      </div>
    )
  }
}

export default BarcodeReader
