import React from 'react'
import AssetGroupEditor from './asset_group_editor'
import AssetGroupPrinting from './asset_group_printing'

class AssetGroupsEditor extends React.Component {
  constructor(props) {
    super(props)
    this.renderTab = this.renderTab.bind(this)
    this.renderPanel = this.renderPanel.bind(this)
    this.isShown = this.isShown.bind(this)
    this.classSelection = this.classSelection.bind(this)
  }
  renderTab(assetGroupId, index) {
    const assetGroup = this.props.assetGroups[assetGroupId]
    const selectedClass = assetGroup.selected === true ? 'active' : ''
    return (
      <li
        style={{ cursor: 'pointer' }}
        onClick={$.proxy(this.props.onSelectAssetGroup, this, assetGroup)}
        role="presentation"
        className={this.classSelection(assetGroup)}
        key={assetGroupId}
      >
        <a
          onClick={$.proxy(this.onSelectAssetGroup, this, assetGroup)}
          key={assetGroupId}
          aria-controls={assetGroup.condition_group_name}
          role="tab"
        >
          {assetGroup.name}
        </a>
      </li>
    )
  }
  classSelection(assetGroup) {
    return this.isShown(assetGroup) ? 'active' : ''
  }
  isShown(assetGroup) {
    return this.props.selectedAssetGroup == assetGroup.id
  }
  renderPanel(assetGroupId, index) {
    const assetGroup = this.props.assetGroups[assetGroupId]
    return (
      <div
        role="tabpanel"
        className={'tab-pane ' + this.classSelection(assetGroup)}
        id={'asset-group-' + assetGroup.id}
        key={'asset-group-' + assetGroup.id}
      >
        <div className="panel panel-default">
          {this.props.allowPrinting && (
            <div className="print-asset-group-header">
              <AssetGroupPrinting
                assetGroup={assetGroup}
                tubePrinter={this.props.tubePrinter}
                platePrinter={this.props.platePrinter}
                onErrorMessage={this.props.onErrorMessage}
              ></AssetGroupPrinting>
            </div>
          )}
          <AssetGroupEditor
            assetGroup={assetGroup}
            uuidsPendingRemoval={this.props.uuidsPendingRemoval}
            dataAssetDisplay={this.props.dataAssetDisplay}
            activityRunning={this.props.activityRunning}
            onCollapseFacts={this.props.onCollapseFacts}
            collapsedFacts={this.props.collapsedFacts}
            onExecuteStep={this.props.onExecuteStep}
            isShown={this.isShown(assetGroup)}
            onAddBarcodesToAssetGroup={this.props.onAddBarcodesToAssetGroup}
            onRemoveAssetFromAssetGroup={this.props.onRemoveAssetFromAssetGroup}
            onRemoveAllAssetsFromAssetGroup={this.props.onRemoveAllAssetsFromAssetGroup}
            onErrorMessage={this.props.onErrorMessage}
            onChangeAssetGroup={this.props.onChangeAssetGroup}
          />
        </div>
      </div>
    )
  }
  render() {
    return (
      <div>
        {/* Tab panes */}
        <div className="tab-content asset-groups">
          <label className="control-label">What do I have?</label>

          {/* Nav tabs */}
          <ul className="nav nav-tabs" role="tablist">
            {Object.keys(this.props.assetGroups).map(this.renderTab)}
          </ul>
          {this.renderPanel(this.props.selectedAssetGroup)}
        </div>
      </div>
    )
  }
}

export default AssetGroupsEditor
