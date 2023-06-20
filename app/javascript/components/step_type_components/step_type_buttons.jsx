import React from 'react'
import StepTypeButton from './step_type_button'

class StepTypeButtons extends React.Component {
  constructor(props) {
    super(props)

    this.renderStepTypeData = this.renderStepTypeData.bind(this)
  }
  renderStepTypeData(stepTypeData, pos) {
    return (
      <StepTypeButton
        key={'step-type-' + stepTypeData.stepType.id}
        stepTypeData={stepTypeData}
        activityRunning={this.props.activityRunning}
        assetGroupId={this.props.assetGroupId}
        onExecuteStep={this.props.onExecuteStep}
        selectedTubePrinter={this.props.selectedTubePrinter}
        selectedPlatePrinter={this.props.selectedPlatePrinter}
      />
    )
  }
  render() {
    return this.props.stepTypesData.map(this.renderStepTypeData)
  }
}

export default StepTypeButtons
