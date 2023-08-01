import StepTypes from './step_types'
import classNames from 'classnames'

const StepTypesActive = (props) => {
  return (
    <div
      className={classNames({
        'panel panel-default': true,
        step_types_active: props.instanceId === '1',
      })}
    >
      <div
        className="panel-body"
        data-psd-component-class="LoadingIcon"
        data-psd-component-parameters='{ "iconClass": "glyphicon", "containerIconClass": "spinner", "loadingClass": "fast-right-spinner"}'
      >
        <div className="spinner" style={{ display: 'none' }}>
          <span className="glyphicon glyphicon-refresh"></span> Please, wait while we refresh this content...
        </div>
        <div className="content_step_types">
          <StepTypes
            instanceId={props.instanceId}
            activityRunning={props.activityRunning}
            assetGroupId={props.assetGroupId}
            onExecuteStep={props.onExecuteStep}
            selectedTubePrinter={props.selectedTubePrinter}
            selectedPlatePrinter={props.selectedPlatePrinter}
            stepTypesData={props.activeStepTypes ? props.activeStepTypes.stepTypesData : []}
            stepTypesTemplatesData={props.activeStepTypes ? props.activeStepTypes.stepTypesTemplatesData : []}
          />
        </div>
      </div>
    </div>
  )
}

export default StepTypesActive
