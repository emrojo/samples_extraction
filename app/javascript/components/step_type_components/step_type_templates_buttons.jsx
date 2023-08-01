import React from 'react'
import StepTypeTemplateButton from './step_type_template_button'

class StepTypeTemplatesButtons extends React.Component {
  constructor(props) {
    super(props)

    this.renderTemplateData = this.renderTemplateData.bind(this)
  }
  renderTemplateData(stepTypeTemplateData, pos) {
    return (
      <StepTypeTemplateButton
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
    return this.props.stepTypesTemplatesData.map(this.renderTemplateData)
  }
}

export default StepTypeTemplatesButtons
