;(function ($, undefined) {
  function RackWellDisplay(node, params) {
    this.node = $(node)
    this.params = params

    this.attachHandlers()
  }

  var proto = RackWellDisplay.prototype

  proto.attachHandlers = function () {
    $('svg', this.node).on('click', $.proxy(this.toggleSize, this))
    for (var key in this.params) {
      var node = $('svg .' + key, this.node)
      node.addClass(this.params[key].cssClass)
      $(node).on('mouseover', $.proxy(this.showTubeDescription, this, this.params[key].title))
      $(node).on('mouseout', $.proxy(this.hideTubeDescription, this))
      $(node).on('mouseover', $.proxy(this.markRelatedLink, this, this.params[key].url))
      $(node).on('mouseout', $.proxy(this.unmarkRelatedLink, this, this.params[key].url))

      var relatedLinks = $('a[href="' + this.params[key].url + '"]', this.node)
      relatedLinks.on('mouseover', $.proxy(this.markRelatedWell, this, node))
      relatedLinks.on('mouseout', $.proxy(this.unmarkRelatedWell, this, node))

      node.on('click', $.proxy(this.linkTo, this, this.params[key].url))
    }
  }

  proto.hideTubeDescription = function () {
    $('svg .barcode', this.node).hide()
  }

  proto.markRelatedLink = function (url) {
    $('a[href="' + url + '"]', this.node).addClass('active')
  }

  proto.unmarkRelatedLink = function (url) {
    $('a[href="' + url + '"]', this.node).removeClass('active')
  }

  proto.markRelatedWell = function (well) {
    $(well).addClass('active')
  }

  proto.unmarkRelatedWell = function (well) {
    $(well).removeClass('active')
  }

  proto.showTubeDescription = function (title) {
    $('svg .barcode', this.node).html(title)
    $('svg .barcode', this.node).show()
  }

  proto.linkTo = function (url) {
    if ($('svg', this.node).hasClass('enlarge')) {
      //window.location.href = url;
    }
  }

  proto.toggleSize = function () {
    $('svg', this.node).toggleClass('enlarge')
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      RackWellDisplay: RackWellDisplay,
    })
  })
})(jQuery)
