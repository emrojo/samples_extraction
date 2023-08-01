;(function () {
  function FinishStepButton(node, params) {
    this.node = $(node)
    this.node.parent().on(
      'click',
      $.proxy(function () {
        $('form', this.node).submit()
      }, this)
    )
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      FinishStepButton: FinishStepButton,
    })
  })
})()
