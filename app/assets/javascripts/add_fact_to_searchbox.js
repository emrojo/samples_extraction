;(function ($, undefined) {
  function AddFactToSearchbox(node, params) {
    this.node = $(node)

    this.attachHandlers()
  }

  var proto = AddFactToSearchbox.prototype

  proto.addFactToSearchbox = function (event) {
    var node = event.currentTarget
    var predicate = $(node).data('psd-fact-predicate')
    var object = $(node).data('psd-fact-object')
    predicate = predicate || $('.predicate', node).text().trim()
    object = object || $('.object', node).text().trim()

    this.node.trigger('fact_searcher.add_fact_to_searchbox', {
      predicate: predicate,
      object: object,
    })
  }

  proto.attachHandlers = function () {
    $('.fact', this.node).on('click', $.proxy(this.addFactToSearchbox, this))
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      AddFactToSearchbox: AddFactToSearchbox,
    })
  })
})(jQuery)
