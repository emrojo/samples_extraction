import React from 'react'
import SVG from 'react-inlinesvg'

class FactsImage extends React.Component {
  imageForFacts(facts) {
    //"/assets/24_rack.svg"
  }

  render() {
    return (
      <div className="svg">
        <SVG
          src={this.imageForFacts(this.props.facts)}
          /*preloader={<Loader />}*/
          onLoad={(src) => {
            /*debugger
              myOnLoadHandler(src);*/
          }}
        >
          Here's some optional content for browsers that don't support XHR or inline SVGs. You can use other React
          components here too. Here, I'll show you.
          <img src="/path/to/myfile.png" />
        </SVG>
      </div>
    )
  }
}

export default FactsImage
