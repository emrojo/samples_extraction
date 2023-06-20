import React from 'react'
import { FormFor } from 'react-rails-form-helpers'
import PrintersSelectionHidden from '../activity_components/printers_selection_hidden'
import ButtonWithLoading from '../lib/button_with_loading'

class StepTypeButton extends React.Component {
  constructor(props) {
    super(props)

    this.onClick = this.onClick.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)
  }
  onAjaxSuccess(msg, text) {
    if (msg.errors) {
      msg.errors.forEach(this.props.onErrorMessage)
    } else {
      this.props.onExecuteStep(msg)
    }
  }
  onClick(e) {
    e.preventDefault()
    $.ajax({
      method: 'post',
      url: this.props.stepTypeData.createStepUrl,
      success: this.onAjaxSuccess,
      data: {
        step: {
          step_type_id: this.props.stepTypeData.stepType.id,
          asset_group_id: this.props.assetGroupId,
          tube_printer_id: this.props.selectedTubePrinter,
          plate_printer_id: this.props.selectedPlatePrinter,
        },
      },
    })
  }
  renderButton() {
    return (
      <ButtonWithLoading
        onClick={this.onClick}
        data-turbolinks="false"
        type="submit"
        className="btn btn-primary"
        text={this.props.stepTypeData.name}
      />
    )
  }
  render() {
    return (
      <li className="btn-group" style={{ top: '6px' }}>
        <form className="form-inline activity-desc">
          <ButtonWithLoading
            onClick={this.onClick}
            data-turbolinks="false"
            type="submit"
            className="btn btn-primary"
            text={this.props.stepTypeData.name}
          />
        </form>
      </li>
    )
  }
}

export default StepTypeButton
