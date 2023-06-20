import React from 'react'
import StepsFinished from '../step_components/steps_finished'
import Togglable from '../lib/togglable'
import Toggle from 'react-toggle'

class Steps extends React.Component {
  constructor(props) {
    super(props)
    this.renderTogglable = this.renderTogglable.bind(this)
    this.renderSteps = this.renderSteps.bind(this)
  }
  renderSteps() {
    return (
      <StepsFinished
        steps={this.props.steps}
        onChangeStateStep={this.props.onChangeStateStep}
        activityRunning={this.props.activityRunning}
      />
    )
  }
  renderTogglable() {
    return (
      <div className="panel panel-default">
        <div className="panel-body">{this.renderSteps()}</div>
      </div>
    )
  }
  render() {
    return Togglable('What happened before?', this.props.steps, this.props.onToggle, this.renderTogglable)
  }
}

export default Steps
