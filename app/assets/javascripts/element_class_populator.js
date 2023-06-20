;(function ($, undefined) {
  function ElementClassPopulator(node, params) {
    this.node = node
    this.params = params

    this.addClasses(this.params)
  }

  var proto = ElementClassPopulator.prototype

  proto.addClasses = function (params) {
    if (typeof params !== 'undefined') {
      for (var i = 0; i < params.length; i++) {
        for (var j = 0; j < params[i].selectors.length; j++) {
          $(params[i].selectors[j]).addClass(params[i].name)
        }
      }
    }
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      ElementClassPopulator: ElementClassPopulator,
    })
  })
})(jQuery)
