import React from 'react'
import Fact from '../asset_components/fact'
import FactsSvg from '../asset_components/facts_svg'

class Facts extends React.Component {
  constructor(props) {
    super(props)
    this.state = { collapsed: {} }
  }
  collapsedPredicate(facts) {
    return facts[0].predicate
  }
  onClickCollapse(predicate) {
    this.state.collapsed[predicate] = !this.isCollapsed(predicate)
    this.setState({ collapsed: this.state.collapsed })
  }
  isCollapsed(predicate) {
    if (typeof this.state.collapsed[predicate] === 'undefined') {
      return true
    } else {
      return this.state.collapsed[predicate]
    }
  }
  renderCollapsedControl(classifiedFacts, posPredicate) {
    let predicate = this.collapsedPredicate(classifiedFacts)
    return (
      <div
        key={posPredicate}
        onClick={() => {
          this.onClickCollapse(predicate)
        }}
        className="fact administrator-allowed"
      >
        <span className={'label label-warning'}>
          <span className={'glyphicon ' + (this.isCollapsed(predicate) ? 'glyphicon-plus' : 'glyphicon-minus')}></span>
          &nbsp;
          <span className="predicate">{this.collapsedPredicate(classifiedFacts)}</span>:<span className="object"></span>
          <span>({classifiedFacts.length})</span>
        </span>
      </div>
    )
  }

  renderCollapsedList(classifiedFacts, posPredicate) {
    if (classifiedFacts.length == 1) {
      return this.renderFact(classifiedFacts[0], posPredicate + '-1')
    } else {
      let render = [this.renderCollapsedControl(classifiedFacts, posPredicate)]
      let predicate = this.collapsedPredicate(classifiedFacts)
      if (!this.isCollapsed(predicate)) {
        render = render.concat(
          classifiedFacts.map((fact, pos) => {
            return this.renderFact(fact, posPredicate + '-' + pos)
          })
        )
      }
      return render
    }
  }
  renderCollapsedFacts(facts) {
    let rendered = []
    const factsByPredicate = this.factsByPredicate(facts)
    let posPredicate = 0
    for (var predicate in factsByPredicate) {
      rendered.push(this.renderCollapsedList(factsByPredicate[predicate], posPredicate))
      posPredicate += 1
    }
    return rendered
  }

  factsByPredicate(facts) {
    return facts.reduce((memo, fact) => {
      if (!memo[fact.predicate]) {
        memo[fact.predicate] = [fact]
      } else {
        memo[fact.predicate].push(fact)
      }
      return memo
    }, {})
  }

  renderFact(fact, index) {
    return <Fact fact={fact} key={index} onRemoveFact={this.props.onRemoveFact} />
  }
  render() {
    if (!this.props.facts || this.props.facts.length == 0) {
      return null
    }
    return (
      <span className="facts-list ">
        <span>
          <FactsSvg asset={this.props.asset} facts={this.props.facts} dataAssetDisplay={this.props.dataAssetDisplay} />
          <div className="col-xs-10">{this.renderCollapsedFacts(this.props.facts)}</div>
        </span>
      </span>
    )
  }
}
export default Facts
