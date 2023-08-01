;(function ($, undefined) {
  function StepCancellable(node, params) {
    this.node = $(node)
    this.params = params

    this.url = this.params.url

    this.input = $('input[type=checkbox]', this.node)
    this.attachHandlers()
  }

  var proto = StepCancellable.prototype

  proto.onClick = function () {
    this.input[0].checked ? this.remake() : this.cancel()
  }

  proto.remake = function () {
    var answer = { step: { state: 'complete' } }
    this.send(answer)
  }

  proto.cancel = function () {
    var answer = { step: { state: 'cancel' } }
    this.send(answer)
  }

  proto.send = function (answer) {
    return $.ajax({
      url: this.url,
      type: 'PUT',
      data: answer,
      dataType: 'json',
      success: $.proxy(this.onReceive, this),
    })
  }

  proto.onReceive = function (msg) {
    var isCancelled = msg.state === 'cancel'
    this.node.toggleClass('cancelled', isCancelled)
    this.node.attr('checked', !isCancelled)
  }

  proto.attachHandlers = function () {
    this.input.on('change', $.proxy(this.onClick, this))
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      StepCancellable: StepCancellable,
    })
  })
})(jQuery)
