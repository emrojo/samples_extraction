import React from 'react'
import Moment from 'react-moment'
import Operations from '../step_components/operations'
import classNames from 'classnames'
import Text from 'react-format-text'
import Toggle from 'react-toggle'
import StepControl from '../step_components/step_control'
import C from './step_states'

class StepsFinished extends React.Component {
  constructor() {
    super()
    this.colorForState = this.colorForState.bind(this)
    this.classImageForState = this.classImageForState.bind(this)
    this.imageForState = this.imageForState.bind(this)
    this.textColorForState = this.textColorForState.bind(this)
    this.renderStepRow = this.renderStepRow.bind(this)
  }
  colorForState(state) {
    switch (state) {
      case C.STEP_STATE_COMPLETED:
        return 'success'
      case C.STEP_STATE_FAILED:
      case C.STEP_STATE_CANCELLED:
      case C.STEP_STATE_STOPPED:
        return 'danger'
      case C.STEP_STATE_RUNNING:
      case C.STEP_STATE_CANCELLING:
      case C.STEP_STATE_CONTINUING:
      case C.STEP_STATE_REMAKING:
      case C.STEP_STATE_PENDING:
        return 'warning'
      case C.STEP_STATE_IN_PROGRESS:
        return 'info'
      default:
        return 'primary'
    }
  }
  classImageForState(state) {
    switch (state) {
      case C.STEP_STATE_COMPLETED:
        return 'glyphicon-ok'
      case C.STEP_STATE_FAILED:
        return 'glyphicon-remove'
      case C.STEP_STATE_PENDING:
      case C.STEP_STATE_STOPPED:
        return 'glyphicon-warning-sign'
      case C.STEP_STATE_RUNNING:
      case C.STEP_STATE_CANCELLING:
      case C.STEP_STATE_CONTINUING:
      case C.STEP_STATE_REMAKING:
        return 'glyphicon-refresh fast-right-spinner'
      case C.STEP_STATE_CANCELLED:
        return 'glyphicon-erase'
      case C.STEP_STATE_IN_PROGRESS:
        return 'glyphicon-repeat'
      default:
        return ''
    }
  }
  imageForState(state) {
    const classToAssign = 'glyphicon ' + this.classImageForState(state) + ' ' + this.textColorForState(state)

    return <span className={classToAssign}></span>
  }
  textColorForState(state) {
    return 'text-' + this.colorForState(state)
  }
  renderStepOutput(step) {
    if (step.output) {
      return (
        <table className="table">
          <thead>
            <tr>
              <th>Output</th>
            </tr>
          </thead>
          <tbody>
            <tr className="output">
              <td>
                <Text>{step.output}</Text>
              </td>
            </tr>
          </tbody>
        </table>
      )
    }
  }
  renderDuration(step) {
    if (step.started_at && step.finished_at) {
      return (
        <span>
          <Moment unit="seconds" diff={step.started_at}>
            {step.finished_at}
          </Moment>
          s
        </span>
      )
    } else {
      return ''
    }
  }
  renderStepRow(step, index) {
    const stepTypeName = step.step_type ? step.step_type.name : ''
    const stepActivityId = step.activity ? step.activity.id : ''
    const stepAssetGroup = step.assetGroup ? step.assetGroup.id : ''
    const stepUsername = step.username
    const classForState = step.state == C.STEP_STATE_RUNNING ? 'spinner' : ''

    const dataTarget = '#step-' + step.id
    if (step.deprecated == true) {
      return
    } else {
      return (
        <React.Fragment key={index}>
          <tr
            data-toggle="collapse"
            data-target={dataTarget}
            data-psd-step-id={step.id}
            key={'a1-' + index}
            className={'clickable  ' + this.colorForState(step.state)}
          >
            <td>{step.id}</td>
            <td>{stepTypeName}</td>
            <td>{stepActivityId}</td>
            <td>{stepAssetGroup}</td>
            <td>{step.operations.length}</td>
            <td>{this.renderDuration(step)}</td>
            <td>{stepUsername}</td>
            <td className={classForState}>
              {step.state} &nbsp;
              {this.imageForState(step.state)}
            </td>
          </tr>
          <tr key={'a2' + index} className="operations ">
            <td colSpan="7">
              <div id={'step-' + step.id} className="collapse">
                <div className="col-md-12" style={{ paddingTop: '1em', paddingBottom: '1em' }}>
                  <StepControl
                    step={step}
                    onChangeStateStep={this.props.onChangeStateStep}
                    isDisabled={this.props.activityRunning && !step.state === null}
                  />
                </div>
                <table className="table">
                  <thead>
                    <tr>
                      <th>Action</th>
                      <th>Barcode</th>
                      <th>Fact</th>
                    </tr>
                  </thead>
                  <tbody>
                    <Operations operations={step.operations} />
                  </tbody>
                </table>
                {this.renderStepOutput(step)}
              </div>
            </td>
          </tr>
        </React.Fragment>
      )
    }
  }
  renderHeaders() {
    return (
      <thead>
        <tr>
          <th>Step id</th>
          <th>Step type</th>
          <th>Activity</th>
          <th>Asset Group</th>
          <th>Num. operations</th>
          <th>Duration</th>
          <th>Username</th>
          <th>Status</th>
        </tr>
      </thead>
    )
  }
  renderSteps() {
    if (this.props.steps.length == 0) {
      return (
        <div className="empty-description">
          <span>This activity has no steps yet.</span>
        </div>
      )
    } else {
      return (
        <table className="table table-condensed table-hover steps-table">
          {this.renderHeaders()}
          <tbody>{this.props.steps.map(this.renderStepRow)}</tbody>
        </table>
      )
    }
  }
  render() {
    return this.renderSteps()
  }
}

export default StepsFinished
