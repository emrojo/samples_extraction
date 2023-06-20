import React from 'react'
import AssetDisplay from '../asset_components/asset_display'
import Facts from '../asset_components/facts'
import ButtonWithLoading from '../lib/button_with_loading'
import classNames from 'classnames'

class AssetGroup extends React.Component {
  constructor(props) {
    super(props)
    this.removeAsset = this.removeAsset.bind(this)
    this.removeAllAssets = this.removeAllAssets.bind(this)
    this.renderAssetRow = this.renderAssetRow.bind(this)
  }
  removeAsset(asset, pos, e) {
    e.preventDefault()
    this.props.onRemoveAssetFromAssetGroup(this.props.assetGroup, asset, pos)
  }
  removeAllAssets(e) {
    e.preventDefault()
    this.props.onRemoveAllAssetsFromAssetGroup(this.props.assetGroup)
  }
  runningAsset(asset) {
    const found = this.props.assetGroup.assets_running.find((uuid) => {
      return uuid == asset.uuid
    })
    if (found) {
      return (
        <div className="spinner">
          <span className="glyphicon glyphicon-refresh fast-right-spinner"></span>
        </div>
      )
    }
  }
  renderAssetRow(asset, index) {
    return (
      <tr
        data-asset-uuid={asset.uuid}
        data-psd-component-class="LoadingIcon"
        data-psd-component-parameters='{ "iconClass": "glyphicon",
        "containerIconClass": "spinner", "loadingClass":
        "fast-right-spinner"}'
        key={asset.uuid}
        className={classNames({
          'bg-warning': this.props.uuidsPendingRemoval.includes(asset.uuid),
        })}
      >
        <td>
          {this.runningAsset(asset)}
          <input type="hidden" name="asset_group[assets]" value={asset.uuid} />
          <AssetDisplay asset={asset} />
        </td>
        <td data-psd-component-class="AddFactToSearchbox">
          <Facts
            asset={asset}
            facts={asset.facts}
            key={'facts-' + index}
            onCollapseFacts={this.props.onCollapseFacts}
            collapsedFacts={this.props.collapsedFacts}
            dataAssetDisplay={this.props.dataAssetDisplay}
          />
        </td>
        <td>{index + 1}</td>
        <td>
          <ButtonWithLoading /*disabled={this.props.activityRunning}*/
            onClick={$.proxy(this.removeAsset, this, asset, index)}
            className="btn btn-primary "
            text="Delete"
          />
        </td>
      </tr>
    )
  }

  render() {
    if (this.props.assetGroup.assets.length == 0) {
      return (
        <div className="empty-description">
          <span>This activity has no assets selected yet.</span>
        </div>
      )
    } else {
      return (
        <table className="table table-condensed">
          <thead>
            <tr>
              <th>Barcode</th>
              <th>Facts</th>
              <th>Position</th>
              <th>
                <ButtonWithLoading
                  /*disabled={this.props.activityRunning}*/ onClick={this.removeAllAssets}
                  className="btn btn-primary"
                  text="Delete all"
                />
              </th>
            </tr>
          </thead>
          <tbody data-psd-asset-group-content="1">{this.props.assetGroup.assets.map(this.renderAssetRow)}</tbody>
        </table>
      )
    }
  }
}

export default AssetGroup
