import React from 'react'
import { FormFor } from 'react-rails-form-helpers'
import BarcodeReader from '../asset_group_components/barcode_reader'
import AssetGroup from '../asset_group_components/asset_group'
import FineUploaderTraditional from 'fine-uploader-wrappers'
import Dropzone from 'react-fine-uploader/dropzone'
import 'react-fine-uploader/gallery/gallery.css'

import { uploaderOptions } from '../lib/uploader_utils'
/**
 assetGroup {
    updateUrl: url to update the asset group (not in use for the moment)
  }
  activityRunning: boolean saying if there is any process running in the activity
  isShown: probably not needed
  uuidsPendingRemoval: list of uuids where the user has click on 'delete' from the group
  dataAssetDisplay
  onCollapseFacts: handler when collapsing a list of fields
  collapsedFacts: hashmap where the keys are fact predicates and the values are a boolean
  representing if the fact is collapsed or not
  onRemoveAssetFromAssetGroup
  onRemoveAllAssetsFromAssetGroup: handler when clearing al assets from a group
  onErrorMessage: handler for errors
  onChangeAssetGroup: handler when the asset group changes
  onAddBarcodesToAssetGroup: handler when adding a new barcode to the group
**/
class AssetGroupEditor extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      barcodesInputText: '',
      disabledBarcodesInput: false,
      assets_status: {},
    }
    this.onSubmit = this.onSubmit.bind(this)
    this.onAjaxSuccess = this.onAjaxSuccess.bind(this)
    this.onAjaxComplete = this.onAjaxComplete.bind(this)
    this.handleBarcodeReaderChange = this.handleBarcodeReaderChange.bind(this)
    this.assetsChanging = this.assetsChanging.bind(this)
  }
  handleBarcodeReaderChange(e) {
    this.setState({ barcodesInputText: e.target.value })
  }
  onAjaxSuccess(msg, text) {
    if (msg.errors) {
      msg.errors.forEach(this.props.onErrorMessage)
    } else {
      this.props.onChangeAssetGroup(msg)
    }
  }
  onAjaxComplete() {
    this.setState({ disabledBarcodesInput: false, barcodesInputText: '' })
  }
  onSubmit(e) {
    e.preventDefault()
    this.setState({ disabledBarcodesInput: true })
    this.props.onAddBarcodesToAssetGroup(this.props.assetGroup, this.state.barcodesInputText)
    this.onAjaxComplete()
  }
  assetsChanging() {
    return Object.keys(this.state.assets_status).filter(
      $.proxy(function (uuid) {
        return this.state.assets_status[uuid] == 'running'
      }, this)
    )
  }
  render() {
    return (
      <Dropzone uploader={new FineUploaderTraditional(uploaderOptions(this.props))}>
        <FormFor
          url={this.props.assetGroup.updateUrl}
          data-turbolinks="false"
          onSubmit={this.onSubmit}
          className="edit_asset_group"
        >
          <div className="panel-header barcode-adding-control">
            <BarcodeReader
              activityRunning={this.props.activityRunning}
              isShown={this.props.isShown}
              onAddBarcodesToAssetGroup={this.props.onAddBarcodesToAssetGroup}
              handleChange={this.handleBarcodeReaderChange}
              barcodesInputText={this.state.barcodesInputText}
              disabledBarcodesInput={this.state.disabledBarcodesInput}
              assetGroup={this.props.assetGroup}
            />
          </div>
          <div className="panel-body collapse in" id="collapseAssets">
            <AssetGroup
              uuidsPendingRemoval={this.props.uuidsPendingRemoval}
              dataAssetDisplay={this.props.dataAssetDisplay}
              activityRunning={this.props.activityRunning}
              onCollapseFacts={this.props.onCollapseFacts}
              collapsedFacts={this.props.collapsedFacts}
              onRemoveAssetFromAssetGroup={this.props.onRemoveAssetFromAssetGroup}
              onRemoveAllAssetsFromAssetGroup={this.props.onRemoveAllAssetsFromAssetGroup}
              assetGroup={this.props.assetGroup}
            />
          </div>
          <div className="panel-footer"></div>
        </FormFor>
      </Dropzone>
    )
  }
}

export default AssetGroupEditor
