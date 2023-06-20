import React from 'react'

class ButtonWithLoading extends React.Component {
  constructor(props) {
    super(props)
    this.onClick = this.onClick.bind(this)
    this.toggleDisableButton = this.toggleDisableButton.bind(this)
    this.propsForButton = this.propsForButton.bind(this)
    this.state = {
      disabledButton: false,
      lastText: null,
    }
  }
  componentDidUpdate(prevProps, prevState, snapshot) {
    if (this.props.text !== this.state.lastText) {
      this.toggleDisableButton(false)
    }
  }
  toggleDisableButton(flag) {
    this.setState({ disabledButton: flag, lastText: this.props.text })
  }
  onClick(e) {
    this.toggleDisableButton(true)
    if (typeof this.props.onClick !== 'undefined') {
      this.props.onClick(e)
    }
  }
  propsForButton() {
    return Object.assign({}, this.props, {
      onClick: this.onClick,
      disabled: this.state.disabledButton,
      text: null,
    })
  }
  render() {
    const text = this.props.text
    const loadingIcon = (
      <span className="glyphicon glyphicon-refresh fast-right-spinner" aria-hidden="true">
        {' '}
      </span>
    )
    const hiddenLoadingIcon = (
      <span className="glyphicon glyphicon-refresh invisible" aria-hidden="true">
        {' '}
      </span>
    )
    const propsToUse = this.propsForButton()

    return (
      <button {...propsToUse}>
        {text}
        {propsToUse.disabled ? loadingIcon : hiddenLoadingIcon}
      </button>
    )
  }
}

export default ButtonWithLoading
