;(function ($, undefined) {
  function FactReader(node, params) {
    this.node = $(node)
    if (params && params.template) {
      this.template = JST[params.template]
      this.node.append(this.template())
    }
    this.actionType = null
    if (params && params.actionType) {
      this.actionType = params.actionType
    }

    this.select = $('[data-psd-fact-reader-operation-selector]', node)
    this.input = $('[data-psd-fact-reader-text-input]', node)
    this.selectButtonText = $('span[data-psd-fact-reader-button-text]', this.node)
    this.addButton = $('[data-psd-fact-reader-add]', node)
    this.attachHandlers()
  }

  var proto = FactReader.prototype

  proto.selectOperationHandler = function (e) {
    this.actionType = $(e.target).data('psd-fact-reader-action-type')
    this.cssClasses = $('span', e.target)[0].className
    this.selectButtonText.html($(e.target).contents().clone())
    //e.stopPropagation();
    e.preventDefault()
    //return false;
  }

  proto.addFactHandler = function () {
    if (this.actionType === null) {
      $(document).trigger('msg.display_error', {
        msg: 'You need to select an operation to add a new fact',
      })
      return false
    }

    var textInput = this.input.val()
    if (textInput.length === 0) {
      $(document).trigger('msg.display_error', {
        msg: 'You need to supply an input',
      })
      return false
    }

    if (textInput.search(/:/) >= 0) {
      var list = textInput.split(':')
      this.predicate = list[0]
      this.object = list[1]
    } else {
      this.predicate = 'is'
      this.object = textInput
    }

    var fact = {
      actionType: this.actionType,
      predicate: this.predicate,
      object: this.object,
      cssClasses: this.cssClasses,
    }
    $(this.node).trigger('fact.fact_reader', fact)
    this.input.val('')
  }

  proto.readTabulatorHandler = function (e) {
    if (e.keyCode === 9) {
      this.addFactHandler()
      e.preventDefault()
    }
    if (e.keyCode == 13) {
      this.addFactHandler()
      e.preventDefault()
    }
  }

  proto.attachHandlers = function (node) {
    this.select.on('click', 'a', $.proxy(this.selectOperationHandler, this))
    this.input.on('keydown', $.proxy(this.readTabulatorHandler, this))
    this.addButton.on('click', $.proxy(this.addFactHandler, this))
  }

  //window.FactReader = FactReader;
  $(document).trigger('registerComponent.builder', { FactReader: FactReader })
})(jQuery)
