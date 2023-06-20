import StepTypesActive from '../step_type_components/step_types_active'
import Togglable from '../lib/togglable'

const renderTogglable = (props) => {
  const assetGroupId = props.selectedAssetGroup
  const stepTypes = props.stepTypes[assetGroupId]
  return (
    <StepTypesActive
      instanceId={props.instanceId}
      key={assetGroupId}
      assetGroupId={assetGroupId}
      activityRunning={props.activityRunning}
      onExecuteStep={props.onExecuteStep}
      selectedAssetGroup={props.selectedAssetGroup}
      activeStepTypes={stepTypes}
      selectedTubePrinter={props.selectedTubePrinter}
      selectedPlatePrinter={props.selectedPlatePrinter}
    />
  )
}

const StepTypesControl = (props) => {
  return Togglable('What can I do with it?', props.stepTypes, props.onToggle, () => {
    return renderTogglable(props)
  })
}

export default StepTypesControl
