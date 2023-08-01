;(function ($, undefined) {
  function BarcodeReader(node, params) {
    this.node = $(node)
    this.input = $('input', node)
    this.button = $('button', node)

    this.attachHandlers()
  }

  var proto = BarcodeReader.prototype

  proto.readInput = function (e) {
    if (e.keyCode === 9 || e.keyCode == 13) {
      this.send(e)
    }
  }

  proto.attachHandlers = function () {
    this.input.on('keydown', $.proxy(this.readInput, this))
    this.button.on('click', $.proxy(this.send, this))
  }

  proto.readBarcodes = function (str) {
    return str.split(' ').map(function (val) {
      return val.replace(/\"\'/, '')
    })
  }

  proto.send = function (e) {
    e.preventDefault()
    this.readBarcodes(this.input.val()).forEach(
      $.proxy(function (barcode) {
        $(this.node).trigger('barcode.barcode_reader', { barcode: barcode })
      }, this)
    )
    this.input.val('')
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      BarcodeReader: BarcodeReader,
    })
  })
})(jQuery)
