import React from 'react'
import ReactDOM from 'react-dom'

import ReactTooltip from 'react-tooltip'

import ActivityControl from './activity_components/activity_control'
import AlertDisplay from './activity_components/alert_display'
import ActivityDescription from './activity_components/activity_description'
import PrintersSelection from './activity_components/printers_selection'
import AssetGroupsEditor from './asset_group_components/asset_groups_editor'
import Steps from './step_components/steps'
import StepsRunning from './step_components/steps_running'
import StepsFailed from './step_components/steps_failed'
import StepTypesControl from './step_type_components/step_types_control'
import C from './step_components/step_states'

import { FormFor, HashFields } from 'react-rails-form-helpers'

const MAX_BARCODE_SIZE = 255

class Activity extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      uuidsPendingRemoval: [],
      messages: props.messages,
      selectedTubePrinter: props.tubePrinter.defaultValue,
      selectedPlatePrinter: props.platePrinter.defaultValue,
      selectedAssetGroup: props.activity.selectedAssetGroup,
      stepTypes: props.stepTypes,
      assetGroups: props.assetGroups,
      stepsRunning: props.stepsRunning,
      stepsPending: props.stepsPending,
      stepsFinished: props.stepsFinished,
      stepsFailed: props.stepsFailed,
      activityRunning: props.activityRunning,
      dataAssetDisplay: props.dataAssetDisplay,
      collapsedFacts: {},
    }
    this.onSelectAssetGroup = this.onSelectAssetGroup.bind(this)
    this.onChangeAssetGroup = this.onChangeAssetGroup.bind(this)
    this.onErrorMessage = this.onErrorMessage.bind(this)
    this.onRemoveErrorMessage = this.onRemoveErrorMessage.bind(this)
    this.onRemoveAssetFromAssetGroup = this.onRemoveAssetFromAssetGroup.bind(this)
    this.onRemoveAllAssetsFromAssetGroup = this.onRemoveAllAssetsFromAssetGroup.bind(this)
    this.onExecuteStep = this.onExecuteStep.bind(this)
    this.onChangeStateStep = this.onChangeStateStep.bind(this)
    this.changeStateStep = this.changeStateStep.bind(this)

    this.onChangeTubePrinter = this.onChangeTubePrinter.bind(this)
    this.onChangePlatePrinter = this.onChangePlatePrinter.bind(this)

    this.onCollapseFacts = this.onCollapseFacts.bind(this)
    this.onAddBarcodesToAssetGroup = this.onAddBarcodesToAssetGroup.bind(this)

    this.onToggleStepsFinished = this.onToggleStepsFinished.bind(this)

    this.renderStepTypesControl = this.renderStepTypesControl.bind(this)
    this.renderAssetGroupsEditorAndStepTypes = this.renderAssetGroupsEditorAndStepTypes.bind(this)
  }
  componentDidMount() {
    this.listenWebSockets()
  }
  onCollapseFacts(collapsedFacts, uuid, predicate) {
    return () => {
      let obj = Object.create({}, collapsedFacts)
      if (!obj[uuid]) {
        obj[uuid] = {}
      }
      if (obj[uuid][predicate] === true) {
        obj[uuid][predicate] = false
      } else {
        obj[uuid][predicate] = true
      }
      return obj
    }
  }
  listenWebSockets() {
    this.activityChannel = App.cable.subscriptions.create(
      {
        channel: 'ActivityChannel',
        activity_id: this.props.activity.id,
      },
      {
        received: $.proxy(this.onWebSocketsMessage, this),
      }
    )
  }
  getAllAssets() {
    return Object.values(this.state.assetGroups).flat()
  }
  onWebSocketsMessage(msg) {
    let newState

    if (msg.error) {
      newState = { messages: [msg.error] }
    } else {
      var selectedGroup = this.state.selectedAssetGroup
      if (!(msg.assetGroups && msg.assetGroups[selectedGroup])) {
        selectedGroup = Object.keys(msg.assetGroups)[0]
      }

      let uuidsForAllAssets = this.getAllAssets().map((a) => a.uuid)
      this.state.uuidsPendingRemoval.filter((uuid) => !uuidsForAllAssets.includes(uuid))

      newState = {
        uuidsPendingRemoval: [],
        messages: msg.messages,
        selectedAssetGroup: selectedGroup,
        activityRunning: msg.activityRunning,
        dataAssetDisplay: msg.dataAssetDisplay,
        assetGroups: msg.assetGroups,
        stepTypes: msg.stepTypes,
        stepsRunning: msg.stepsRunning || [],
        stepsFailed: msg.stepsFailed,
        stepsPending: msg.stepsPending || [],
        stepsFinished: msg.stepsFinished,
      }
    }

    this.setState(newState)
  }
  onRemoveErrorMessage(msg, pos) {
    this.state.messages.splice(pos, 1)
    this.setState({ messages: this.state.messages })
  }
  onErrorMessage(msg) {
    this.state.messages.push(msg)
    this.setState({ messages: this.state.messages })
  }
  onSelectAssetGroup(assetGroup) {
    this.setState({ selectedAssetGroup: assetGroup.id })
  }
  onChangeAssetGroup(msg) {
    return msg
  }
  changeAssetGroup(assetGroup, data) {
    return this.activityChannel.send(data)
  }
  getAssetUuidsForAssetGroup(assetGroup) {
    let uuids = this.state.uuidsPendingRemoval
    return assetGroup.assets.map((a) => a.uuid).filter((uuid) => !uuids.includes(uuid))
  }

  barcodesFromInput(barcodes) {
    return barcodes.split(' ').filter((b) => {
      return b.length > 0 && b.length < MAX_BARCODE_SIZE && b.match(/\w+/)
    })
  }
  onAddBarcodesToAssetGroup(assetGroup, userInput) {
    return this.changeAssetGroup(assetGroup, {
      asset_group: {
        id: assetGroup.id,
        assets: this.getAssetUuidsForAssetGroup(assetGroup).concat(this.barcodesFromInput(userInput)),
      },
    })
  }
  onRemoveAssetFromAssetGroup(assetGroup, asset, pos) {
    let uuids = this.getAssetUuidsForAssetGroup(assetGroup)

    let removedUuid = asset.uuid
    let newUuids = uuids.filter((uuid) => uuid != removedUuid)

    this.state.uuidsPendingRemoval.push(removedUuid)
    let uuidsPendingRemoval = this.state.uuidsPendingRemoval
    this.setState({ uuidsPendingRemoval })

    return this.changeAssetGroup(assetGroup, {
      asset_group: {
        id: assetGroup.id,
        assets: newUuids,
      },
    })
  }
  onRemoveAllAssetsFromAssetGroup(assetGroup) {
    return this.changeAssetGroup(assetGroup, {
      asset_group: {
        id: assetGroup.id,
        assets: [],
      },
    })
  }

  onChangeStateStep(step, stateEventName) {
    return (e) => {
      // Do not do anything while the activity is running unless the event is stop
      /*if ((this.state.activityRunning === true) && (stateEventName !== C.STEP_EVENT_STOP)) {
        return;
      }*/
      const event_name = stateEventName || (e.target.checked ? C.STEP_EVENT_REMAKE : C.STEP_EVENT_CANCEL)
      this.setState({ activityRunning: true })
      this.changeStateStep(step, event_name).then(
        $.proxy(() => {
          this.setState({ activityRunning: false })
        }, this)
      )
    }
  }

  changeStateStep(step, event_name) {
    return $.ajax({
      method: 'PUT',
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      url: step.stepUpdateUrl,
      data: JSON.stringify({ step: { event_name } }),
    })
  }

  onChangeTubePrinter(e) {
    this.setState({ selectedTubePrinter: e.target.value })
  }
  onChangePlatePrinter(e) {
    this.setState({ selectedPlatePrinter: e.target.value })
  }
  onExecuteStep(msg) {
    this.setState({ activityRunning: true })
  }
  changeShownComponents() {
    this.activityChannel.send({
      activity: {
        id: this.props.activity.id,
        stepsFinished: !this.state.stepsFinished,
      },
    })
  }
  onToggleComponentBuilder(componentName) {
    return () => {
      let msg = { activity: {} }
      msg.activity[componentName] = typeof this.state[componentName] === 'undefined'
      console.log(this.state)
      this.activityChannel.send(msg)
    }
  }
  onToggleStepsFinished() {
    this.changeShownComponents()
  }
  renderStepTypesControl(instanceId) {
    const steps = [].concat(this.state.stepsRunning).concat(this.state.stepsPending)
    if (this.state.stepsFailed && this.state.stepsFailed.length > 0) {
      return <StepsFailed onChangeStateStep={this.onChangeStateStep} steps={this.state.stepsFailed} />
    } else {
      if (this.state.stepsRunning && this.state.stepsRunning.length > 0) {
        return <StepsRunning steps={this.state.stepsRunning} onChangeStateStep={this.onChangeStateStep} />
      } else {
        return (
          <StepTypesControl
            onToggle={this.onToggleComponentBuilder('stepTypes')}
            stepTypes={this.state.stepTypes}
            instanceId={instanceId}
            onExecuteStep={this.onExecuteStep}
            activityRunning={this.state.activityRunning}
            selectedAssetGroup={this.state.selectedAssetGroup}
            selectedTubePrinter={this.state.selectedTubePrinter}
            selectedPlatePrinter={this.state.selectedPlatePrinter}
          />
        )
      }
    }
  }

  renderAssetGroupsEditorAndStepTypes() {
    if (this.props.activityState == 'finish') {
      return null
    } else {
      return (
        <React.Fragment>
          {this.renderStepTypesControl('1')}
          <AssetGroupsEditor
            uuidsPendingRemoval={this.state.uuidsPendingRemoval}
            dataAssetDisplay={this.state.dataAssetDisplay}
            activityRunning={this.state.activityRunning}
            onCollapseFacts={this.onCollapseFacts}
            collapsedFacts={null} // {this.state.collapsedFacts}
            onExecuteStep={this.onExecuteStep}
            onAddBarcodesToAssetGroup={this.onAddBarcodesToAssetGroup}
            onRemoveAssetFromAssetGroup={this.onRemoveAssetFromAssetGroup}
            onRemoveAllAssetsFromAssetGroup={this.onRemoveAllAssetsFromAssetGroup}
            onErrorMessage={this.onErrorMessage}
            onChangeAssetGroup={this.onChangeAssetGroup}
            selectedAssetGroup={this.state.selectedAssetGroup}
            onSelectAssetGroup={this.onSelectAssetGroup}
            allowPrinting={
              this.props.featureFlags?.dpl348_decouple_automatic_printing_from_steps ||
              this.props.featureFlags?.dpl348_allow_printing_from_activities_pages
            }
            assetGroups={this.state.assetGroups}
            tubePrinter={this.props.tubePrinter}
            platePrinter={this.props.platePrinter}
          />
          {this.renderStepTypesControl('2')}
        </React.Fragment>
      )
    }
  }

  render() {
    return (
      <div>
        <h1>
          Activity {this.props.activity.id}&nbsp;
          <ActivityControl activityRunning={this.state.activityRunning} />
        </h1>

        <ReactTooltip multiline={true} effect="solid" />
        <AlertDisplay onRemoveErrorMessage={this.onRemoveErrorMessage} messages={this.state.messages} />
        <ActivityDescription activity={this.props.activity} />

        {!this.props.featureFlags?.dpl348_decouple_automatic_printing_from_steps && (
          <PrintersSelection
            selectedTubePrinter={this.state.selectedTubePrinter}
            selectedPlatePrinter={this.state.selectedPlatePrinter}
            tubePrinter={this.props.tubePrinter}
            platePrinter={this.props.platePrinter}
            onChangeTubePrinter={this.onChangeTubePrinter}
            onChangePlatePrinter={this.onChangePlatePrinter}
          />
        )}
        {this.renderAssetGroupsEditorAndStepTypes()}
        <Steps
          onToggle={this.onToggleComponentBuilder('stepsFinished')}
          steps={this.state.stepsFinished}
          activityRunning={this.state.activityRunning}
          onChangeStateStep={this.onChangeStateStep}
        />
      </div>
    )
  }
}

export default Activity
