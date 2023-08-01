import React from 'react'
import ReactDOM from 'react-dom'

import { FormFor } from 'react-rails-form-helpers'
import PrintersSelectionHidden from '../activity_components/printers_selection_hidden'
import UploadFile from './step_type_templates/upload_file'
import ApplyFile from './step_type_templates/apply_file'

class StepTypeTemplateControl extends React.Component {
  renderTemplate(template, params) {
    const Template = {
      upload_file: UploadFile,
      rack_layout_creating_tubes: ApplyFile,
      rack_layout: ApplyFile,
      rack_order_symphony: UploadFile,
      racking_by_columns: UploadFile,
      transfer_tube_to_tube: UploadFile,
    }[template]

    return <Template {...params} />
  }
  render() {
    const stepTypeTemplateData = this.props.stepTypeTemplateData
    const template = stepTypeTemplateData.stepType.step_template
    return (
      <div id={stepTypeTemplateData.id + '-' + this.props.instanceId} className="tab-pane container step-type-template">
        <div className="container">{this.renderTemplate(template, stepTypeTemplateData)}</div>

        <FormFor url={stepTypeTemplateData.createStepUrl} className="form-inline activity-desc">
          <PrintersSelectionHidden
            selectedTubePrinter={this.props.selectedTubePrinter}
            selectedPlatePrinter={this.props.selectedPlatePrinter}
          />
          <input type="hidden" name="step[step_type_id]" value={stepTypeTemplateData.stepType.id} />
          <input type="hidden" name="step[asset_group_id]" value={this.props.assetGroupId} />

          <input type="button" name="button" style={{ display: 'none' }} />
          <input type="hidden" name="step[state]" value="done" />
        </FormFor>
      </div>
    )
  }
}

export default StepTypeTemplateControl
