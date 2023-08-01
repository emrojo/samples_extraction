import React from 'react'
import ButtonWithLoading from '../lib/button_with_loading'

class SearchControl extends React.Component {
  constructor(props) {
    super(props)
    this.onClick = this.onClick.bind(this)
    this.onChange = this.onChange.bind(this)
    this.dataFromInput = this.dataFromInput.bind(this)

    this.state = {
      text: '',
    }
  }
  onChange(e) {
    this.setState({ text: e.target.value })
  }
  onClick(e) {
    return $(document.body).html(
      $.get({
        url: this.props.searchUrl,
        data: this.dataFromInput(),
        dataType: 'html',
      })
    )
  }
  dataFromInput() {
    return this.state.text
      .split(' ')
      .reduce((memo, value) => {
        let list = value.split(':')
        if (list.length === 1) {
          memo.push({ predicate: 'barcode', object: list[0] })
        } else {
          memo.push({ predicate: list[0], object: list[1] })
        }
        return memo
      }, [])
      .map((entry, pos) => {
        let obj = {}
        obj['p' + pos] = entry.predicate
        obj['o' + pos] = entry.object
        return obj
      })
      .reduce((memo, value) => {
        Object.keys(value).forEach((key) => {
          memo[key] = value[key]
        })
        return memo
      }, {})
  }

  render() {
    return (
      <form role="search" className="input-group" method="get">
        <input
          id="fact_searcher"
          name="fact_searcher"
          className="form-control searcher"
          onChange={this.onChange}
          value={this.state.text}
          type="text"
          autoComplete="off"
        />
        <span className="input-group-btn">
          <ButtonWithLoading onClick={this.onClick} />
        </span>
      </form>
    )
  }
}

export default SearchControl
