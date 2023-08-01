import React from 'react'

class AssetDisplay extends React.Component {
  render() {
    return (
      <div>
        {this.props.asset.barcode}

        <div className="spinner" style={{ display: 'none' }}>
          <span className="glyphicon glyphicon-refresh"></span>
        </div>
      </div>
    )
  }
}

export default AssetDisplay
