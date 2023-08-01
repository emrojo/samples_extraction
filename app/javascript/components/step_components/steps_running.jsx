import React from 'react'
import Moment from 'react-moment'
import StepsFinished from '../step_components/steps_finished'
import StepControl from '../step_components/step_control'
import C from './step_states'

class StepsRunning extends StepsFinished {
  renderDuration(step) {
    if (step.started_at) {
      return (
        <span>
          <Moment date={step.started_at} fromNow interval={20000} />
        </span>
      )
    } else {
      return ''
    }
  }
  renderHeaders() {
    return (
      <thead>
        <tr>
          <th>Step id</th>
          <th>Step type</th>
          <th>Asset Group</th>
          <th>Username</th>
          <th>Ellapsed time</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
    )
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
          <tr data-psd-step-id={step.id} key={'a1-' + index} className={this.colorForState(step.state)}>
            <td>{step.id}</td>
            <td>{stepTypeName}</td>
            <td>{stepAssetGroup}</td>
            <td>{stepUsername}</td>
            <td>{this.renderDuration(step)}</td>
            <td className={classForState}>
              {step.state} &nbsp;
              {this.imageForState(step.state)}
            </td>
            <td>
              <StepControl
                step={step}
                onChangeStateStep={this.props.onChangeStateStep}
                isDisabled={this.props.activityRunning && !step.state === null}
              />
            </td>
          </tr>
        </React.Fragment>
      )
    }
  }

  render() {
    return (
      <div className="form-group">
        <label className="control-label">What is happening now?</label>
        <div className="panel panel-default">
          <div className="panel-body">{this.renderSteps()}</div>
        </div>
      </div>
    )
  }
}

export default StepsRunning
