;(function ($, undefined) {
  function DisplayError(node) {
    this.node = $(node)
    this.template = JST['templates/display_error']
    this.attachHandlers()
  }
  var proto = DisplayError.prototype
  proto.showMsg = function (e, msg) {
    if (typeof msg.type === 'undefined') {
      msg.type = 'warning'
    }
    this.node.html(this.template(msg))
  }

  proto.attachHandlers = function () {
    $(document).on('msg.display_error', $.proxy(this.showMsg, this))
  }

  $(document).trigger('registerComponent.builder', {
    DisplayError: DisplayError,
  })
})(jQuery)
