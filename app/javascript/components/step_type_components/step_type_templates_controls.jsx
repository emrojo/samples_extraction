import React from 'react'
import StepTypeTemplateControl from './step_type_template_control'

class StepTypeTemplatesControls extends React.Component {
  constructor(props) {
    super(props)

    this.renderTemplateData = this.renderTemplateData.bind(this)
  }
  renderTemplateData(stepTypeTemplateData, pos) {
    return (
      <StepTypeTemplateControl
        instanceId={this.props.instanceId}
        activityRunning={this.props.activityRunning}
        stepTypeTemplateData={stepTypeTemplateData}
        key={pos}
        selectedTubePrinter={this.props.selectedTubePrinter}
        selectedPlatePrinter={this.props.selectedPlatePrinter}
      />
    )
  }
  render() {
    return (
      <div className="step-template-view pull-left">
        <div className="tab-content">{this.props.stepTypesTemplatesData.map(this.renderTemplateData)}</div>
      </div>
    )
  }
}

export default StepTypeTemplatesControls
