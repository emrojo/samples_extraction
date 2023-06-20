import React from 'react'

class Fact extends React.Component {
  constructor(props) {
    super(props)
    this.valueForPredicate = this.valueForPredicate.bind(this)
    this.classType = this.classType.bind(this)
    this.renderShortDescription = this.renderShortDescription.bind(this)
    this.renderObject = this.renderObject.bind(this)
    this.tipForPredicate = this.tipForPredicate.bind(this)
    this.renderRemoveButton = this.renderRemoveButton.bind(this)
  }

  valueForPredicate(asset, predicate) {
    let val =
      asset.facts &&
      asset.facts.filter((a) => {
        return a.predicate == predicate
      })[0]
    if (val) {
      return val.object
    } else {
      return ''
    }
  }

  classType(asset) {
    return this.valueForPredicate(asset, 'a')
  }

  renderShortDescription(asset) {
    let label = asset && asset.barcode ? asset.barcode : '#' + asset.id
    if (asset && asset.info_line) {
      return `${asset.info_line} ${this.classType(asset)} ${label}`
    }
    return `${this.valueForPredicate(asset, 'aliquotType')} ${this.classType(asset)} ${label}`
  }

  renderObject(fact) {
    if (fact.object_asset_id) {
      let url = `/labware/${fact.object_asset_id}`

      return (
        <a className="object-reference" href={url}>
          {fact.object_asset ? this.renderShortDescription(fact.object_asset) : '#' + fact.object_asset_id}
        </a>
      )
    } else {
      return <span data-tip={this.tipForPredicate(fact.object)}>{fact.object}</span>
    }
  }

  tipForPredicate(predicate) {
    if (window.ONTOLOGY && window.ONTOLOGY[predicate]) {
      return window.ONTOLOGY[predicate].description || null
    }
  }

  renderRemoveButton(fact) {
    if (this.props.onRemoveFact) {
      return (
        <span
          onClick={() => {
            this.props.onRemoveFact(fact)
          }}
        >
          ×
        </span>
      )
    }
    return null
  }

  render() {
    const fact = this.props.fact

    return (
      <div className="fact administrator-allowed">
        <span className={'label ' + (fact['is_remote?'] ? 'label-info' : 'label-default')}>
          <span data-tip={this.tipForPredicate(fact.predicate)} className="predicate">
            {fact.predicate}
          </span>
          :<span className="object"></span>
          {this.renderObject(fact)}
          &nbsp;
          {this.renderRemoveButton(fact)}
        </span>
      </div>
    )
  }
}

export default Fact
