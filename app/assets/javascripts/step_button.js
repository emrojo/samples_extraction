;(function ($, undefined) {
  /**
   * Hijacks a form to send a post request to its url without changing the url and reloads afterwards
   */
  function StepButton(node, params) {
    this.node = $(node)
    this.form = this.node
    this.params = params
    this.attachHandlers()
  }

  var proto = StepButton.prototype

  proto.attachHandlers = function (e) {
    $(this.node).on('submit', $.proxy(this.onSubmit, this))
    $('input', this.node).on('click', $.proxy(this.onClick, this))
  }

  proto.onSubmit = function (e) {
    e.preventDefault()
    $.ajax({
      url: this.form.attr('action'),
      method: 'POST',
      data: this.form.serialize(),
      dataType: 'json',
      success: function () {
        window.location.reload()
      },
    })
    return false
  }

  proto.onClick = function (e) {
    e.preventDefault()
    $('.step-selection input.btn').attr('disabled', true)
    this.onSubmit(e)
    return false
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      StepButton: StepButton,
    })
  })
})(jQuery)
