;(function ($, undefined) {
  function DeleteIcon(node) {
    this.node = $(node)

    this.icon = $('[data-psd-delete-icon]', node)
    this.attachHandlers()
  }

  var proto = DeleteIcon.prototype

  proto.deleteElement = function () {
    $(this.node).trigger('deleted_node.delete_icon', { node: this.node })
    this.node.remove()
  }

  proto.attachHandlers = function () {
    this.icon.on('click', $.proxy(this.deleteElement, this))
  }

  $(document).trigger('registerComponent.builder', { DeleteIcon: DeleteIcon })
})(jQuery)
