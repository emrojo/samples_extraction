import React from 'react'

class AlertDisplay extends React.Component {
  constructor(props) {
    super(props)
    this.onRemoveMsg = this.onRemoveMsg.bind(this)
    this.renderMessage = this.renderMessage.bind(this)
  }
  onRemoveMsg(m, pos) {
    this.props.onRemoveErrorMessage(m, pos)
  }
  renderMessage(m, pos) {
    const destroyMessage = $.proxy(this.onRemoveMsg, this, m, pos)

    if (m.type == 'info') {
      setTimeout(destroyMessage, 3000)
    }
    return (
      <div key={pos} className={'alert alert-' + m.type}>
        {m.msg}
        <button onClick={destroyMessage} className="close" type="button">
          <span>&times;</span>
        </button>
      </div>
    )
  }
  render() {
    if (this.props.messages.length == 0) {
      return null
    }
    let messages = this.props.messages.slice(0, 5)
    return (
      <React.Fragment>
        <span className="badge alert-danger">
          {this.props.messages.length} messages, showing {messages.length}
        </span>
        <hr />
        {messages.map(this.renderMessage)}
      </React.Fragment>
    )
  }
}

export default AlertDisplay
