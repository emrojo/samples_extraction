import 'react'

// DEPRECATED
class PairingSources extends React.Component {
  constructor(props) {
    super(props)

    this.renderPairingInputs = this.renderPairingInputs.bind(this)
    this.renderPairingValues = this.renderPairingValues.bind(this)
  }
  renderPairingInputs(pairingInput) {
    let name = pairingInput.name
    let identifier = pairingInput.id

    return (
      <div className="row col-md-12 with-bottom-margin">
        <label for="source" className="control-label">
          Scan a {name}
        </label>
        <div className="">
          <input
            autocomplete="off"
            name="{ identifier }"
            className="form-control"
            type="text"
            placeholder="Scan a { name }"
          />
        </div>
      </div>
    )
  }
  renderPairingValues(values) {
    return (
      <tr>
        {Object.keys(this.props.pairingInputs).map((input) => {
          return <td>{values[input.id]}</td>
        })}
      </tr>
    )
  }
  render() {
    return (
      <div className="row">
        <div className="col-md-3">
          {Object.keys(this.props.pairingInputs).map(this.renderPairingInputs)}
          <div className="row">
            <div className="col-md-12 with-bottom-margin">
              <button className="button btn btn-default reset-button">Reset</button>
              <button className="button btn btn-primary send-button">Transfer</button>
            </div>
          </div>
        </div>
        <div className="col-md-9">
          <div className="row col-md-12">
            <table className="table table-condensed">
              <thead>
                <tr>
                  {Object.keys(this.props.pairingInputs).map((name) => {
                    return <th>{name}</th>
                  })}
                </tr>
              </thead>
              <tbody>{this.props.pairingValues.map(this.renderPairingValues)}</tbody>
            </table>
          </div>
        </div>
      </div>
    )
  }
}
