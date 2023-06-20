import React from 'react'
import ReactDOM from 'react-dom'
import SVG from 'react-inlinesvg'
import classNames from 'classnames'
import ReactTooltip from 'react-tooltip'

class FactsSvg extends React.Component {
  constructor(props) {
    super(props)
    this.numWells = this.numWells.bind(this)
    this.filename = this.filename.bind(this)
    this.pathImage = this.pathImage.bind(this)
    this.nameForFacts = this.nameForFacts.bind(this)
    this.onLoadSvg = this.onLoadSvg.bind(this)
    this.toggleEnlarge = this.toggleEnlarge.bind(this)
    this.classesConfig = this.classesConfig.bind(this)
    this.state = {
      enlarge: false,
      previousValue: {},
    }
  }
  numWells(facts) {
    return facts.filter((v) => {
      return v.predicate == 'contains'
    }).length
  }
  filename(facts) {
    const name = this.nameForFacts(facts)
    if (name == 'plate') {
      if (this.numWells(facts) > 96) {
        return '384_plate'
      } else {
        return '96_plate'
      }
    }
    if (name == 'gel') {
      return '96_gel'
    }
    if (name == 'tuberack') {
      return 'tuberack'
    }
    if (name == 'rack') {
      if (this.numWells(facts) <= 24) {
        return '24_rack'
      } else {
        return 'tuberack'
      }
    }
    if (name == 'sampletube') {
      return 'tube'
    }
    if (name == 'tube') {
      return 'tube'
    }
    if (name == 'spincolumn') {
      return 'spin_column'
    }
    if (name == 'filterpaper') {
      return 'filter_paper'
    }
    return null
  }
  nameForFacts(facts) {
    if (facts.length == 0) {
      return null
    }
    let typeFact = facts.find((v) => {
      return v.predicate == 'a'
    })
    if (!typeFact) {
      return null
    }
    return typeFact.object.toLowerCase()
  }
  pathImage(facts) {
    const img = this.filename(facts)
    if (img) {
      return `/assets/${img}.svg`
    } else {
      return null
    }
  }
  componentDidUpdate(prevProps) {
    this.onLoadSvg(prevProps)
    //ReactTooltip.rebuild()
  }
  toggleEnlarge() {
    this.setState({ enlarge: !this.state.enlarge })
  }
  onLoadSvg(prevProps) {
    var data = this.props.dataAssetDisplay[this.props.asset.uuid]
    var ignoreKeys = []
    for (var key in data) {
      if (
        prevProps &&
        prevProps.dataAssetDisplay &&
        prevProps.dataAssetDisplay[this.props.asset.uuid] &&
        prevProps.dataAssetDisplay[this.props.asset.uuid][key]
      ) {
        ignoreKeys.push(key)
      }
      var node = $('.svg-' + this.props.asset.uuid + ' .' + key)
      // We want to reset all previous css but we also want to
      // to keep the location, that is represented as a css class (key)
      node.attr('class', key + ' ' + data[key].cssClass)
      if (node[0]) {
        node[0].setAttribute('data-tip', data[key].title)
      }
    }
    if (prevProps && prevProps.dataAssetDisplay) {
      var oldData = prevProps.dataAssetDisplay[this.props.asset.uuid]
      for (var key in oldData) {
        if (
          !ignoreKeys.find((e) => {
            return e == key
          })
        ) {
          var node = $('.svg-' + this.props.asset.uuid + ' .' + key)
          // We want to reset all previous css but we also want to
          // to keep the location, that is represented as a css class (key)
          node.attr('class', key)
          if (node[0]) {
            node[0].setAttribute('data-tip', null)
          }
        }
      }
    }
    ReactTooltip.rebuild()
  }

  classesConfig() {
    let classesConfig = {
      svg: true,
      enlarge: this.state.enlarge,
    }
    classesConfig['svg-' + this.props.asset.uuid] = true
    return classNames(classesConfig)
  }

  render() {
    const path = this.pathImage(this.props.facts)

    if (path) {
      return (
        <div className={this.classesConfig()} onClick={this.toggleEnlarge}>
          <SVG
            src={this.pathImage(this.props.facts)}
            ref={(el) => (this.el = el)}
            cacheGetRequests={true}
            onLoad={this.onLoadSvg}
          ></SVG>
        </div>
      )
    } else {
      return (
        <div className="svg" style={{ fontSize: 'xx-large', float: 'left', marginRight: '0.6em' }}>
          <span className="glyphicon glyphicon-file" />
        </div>
      )
    }
  }
}

export default FactsSvg
