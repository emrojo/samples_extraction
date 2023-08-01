import classNames from 'classnames'
import React from 'react'
import C from '../step_components/step_states'
import ButtonWithLoading from '../lib/button_with_loading'

class StepControl extends React.Component {
  constructor(props) {
    super(props)

    this.buildChangeStateHandler = this.buildChangeStateHandler.bind(this)
    this.renderStepRunningControl = this.renderStepRunningControl.bind(this)
    this.renderStepErrorControl = this.renderStepErrorControl.bind(this)
    this.renderStepFinishedControl = this.renderStepFinishedControl.bind(this)
    this.eventNameForState = this.eventNameForState.bind(this)
  }

  buildChangeStateHandler(state) {
    return this.props.onChangeStateStep(this.props.step, state)
  }

  renderStepRunningControl() {
    return (
      <ButtonWithLoading
        onClick={this.buildChangeStateHandler(C.STEP_EVENT_STOP)}
        className="btn btn-danger"
        text="Stop?"
      />
    )
  }
  renderStepErrorControl() {
    return (
      <React.Fragment>
        <ButtonWithLoading
          onClick={this.buildChangeStateHandler(C.STEP_EVENT_RUN)}
          className="btn btn-success"
          text="Retry?"
        />
        &nbsp;
        <ButtonWithLoading
          onClick={this.buildChangeStateHandler(C.STEP_EVENT_STOP)}
          className="btn btn-danger"
          text="Stop?"
        />
      </React.Fragment>
    )
  }
  eventNameForState(state) {
    switch (state) {
      case C.STEP_STATE_STOPPED:
      case C.STEP_STATE_PENDING:
      case C.STEP_STATE_FAILED:
        return C.STEP_EVENT_CONTINUE
      case C.STEP_STATE_FAILED:
      case C.STEP_STATE_RUNNING:
        return C.STEP_EVENT_STOP
      case C.STEP_STATE_CANCELLED:
        return C.STEP_EVENT_REMAKE
      case C.STEP_STATE_COMPLETED:
        return C.STEP_EVENT_CANCEL
      default:
        ''
    }
  }
  renderStepFinishedControl() {
    const state = this.props.step.state

    return (
      <ButtonWithLoading
        disabled={this.props.isDisabled}
        onClick={this.buildChangeStateHandler(this.eventNameForState(state))}
        className={classNames({
          'pull-right btn': true,
          'btn-danger':
            state === C.STEP_STATE_COMPLETED ||
            state === C.STEP_STATE_PENDING ||
            state === C.STEP_STATE_FAILED ||
            state === C.STEP_STATE_RUNNING,
          'btn-primary': state != C.STEP_STATE_COMPLETED,
        })}
        text={classNames({
          'Stop?': state === null || state === C.STEP_STATE_FAILED || state === C.STEP_STATE_RUNNING,
          'Redo?': state === C.STEP_STATE_CANCELLED,
          'Continue?': state === C.STEP_STATE_PENDING || state == C.STEP_STATE_STOPPED || state == C.STEP_STATE_FAILED,
          'Revert?': state === C.STEP_STATE_COMPLETED,
        })}
      />
    )
  }
  render() {
    const state = this.props.step.state
    if (!this.props.onChangeStateStep) {
      return null
    }

    switch (state) {
      case C.STEP_STATE_COMPLETED:
      case C.STEP_STATE_PENDING:
      case C.STEP_STATE_CANCELLED:
      case C.STEP_STATE_STOPPED:
        return this.renderStepFinishedControl()
      case C.STEP_STATE_RUNNING:
      case C.STEP_STATE_CANCELLING:
      case C.STEP_STATE_REMAKING:
      case C.STEP_STATE_CONTINUING:
        return this.renderStepRunningControl()
      case C.STEP_STATE_FAILED:
        return this.renderStepErrorControl()
      default:
        return null
    }
  }
}

export default StepControl
