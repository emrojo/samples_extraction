import React from 'react'
import Facts from '../asset_components/facts'
class FactsEditor extends Facts {
  constructor(props) {
    super(props)
    this.onAddFact = this.onAddFact.bind(this)
    this.onRemoveFact = this.onRemoveFact.bind(this)
    this.onChangeText = this.onChangeText.bind(this)
    this.onKeyPress = this.onKeyPress.bind(this)
    this.updateFromJson = this.updateFromJson.bind(this)

    this.state = {
      text: '',
      asset: this.props.asset,
      facts: this.props.facts,
      dataAssetDisplay: this.props.dataAssetDisplay,
    }
  }

  onAddFact(e) {
    const list = this.state.text.split(':')
    const predicate = list[0]
    const object = list[1]
    return $.ajax({
      method: 'POST',
      url: this.props.changesUrl,
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify({
        changes: {
          add_facts: [[this.props.asset.uuid, predicate, object]],
        },
      }),
    }).then(this.updateFromJson)
  }

  onRemoveFact(fact) {
    return $.ajax({
      method: 'POST',
      url: this.props.changesUrl,
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify({
        changes: {
          remove_facts: [[this.props.asset.uuid, fact.predicate, fact.object || fact.object_asset.uuid]],
        },
      }),
    }).then(this.updateFromJson)
  }

  updateFromJson(json) {
    const asset = json.assets[0]
    const facts = json.facts[0]
    let dataAssetDisplay = {}
    dataAssetDisplay[asset.uuid] = json.dataAssetDisplay[0]

    this.setState({
      text: '',
      asset,
      dataAssetDisplay,
      facts: facts,
    })
  }

  onChangeText(e) {
    this.setState({ text: e.target.value })
  }

  onKeyPress(e) {
    if (e.key === 'Enter') {
      this.onAddFact(e)
    }
  }

  render() {
    return (
      <div className="panel panel-default">
        <div className="panel-body">
          <Facts
            asset={this.state.asset}
            facts={this.state.facts}
            dataAssetDisplay={this.state.dataAssetDisplay}
            onRemoveFact={this.props.changesUrl ? this.onRemoveFact : null}
          />
        </div>
        <div className="panel-footer">
          <div className="input-group">
            <div className="input-group-btn">
              <button disabled="disabled" className="btn btn-default">
                <span className="glyphicon glyphicon-pencil" aria-hidden="true"></span>
                addFacts
              </button>
            </div>
            <input
              disabled={!this.props.changesUrl}
              autoComplete="off"
              type="text"
              name="object"
              value={this.state.text}
              onChange={this.onChangeText}
              className="form-control"
              aria-label="..."
              onKeyPress={this.onKeyPress}
            />
            <div className="input-group-btn">
              <button
                type="button"
                disabled={!this.props.changesUrl}
                onClick={this.props.changesUrl ? this.onAddFact : null}
                className="btn btn-default form-control"
              >
                Add
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

export default FactsEditor
