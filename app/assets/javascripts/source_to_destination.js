;(function () {
  function SourceToDestination(node, params) {
    this.node = $(node)
    this.params = params

    this.template = params.template
    this.names = params.names
    this.identifiers = params.identifiers
    this.pairings = []
    this.dataParamsNode = $(params.paramsNodeQuery) || '#data_params'

    this.firstRender()

    this.addButton = $('.add-button', this.node)
    this.sendbutton = $('.send-button', this.node)
    this.resetButton = $('.reset-button', this.node)
    this.table = $('table', this.node)

    this.attachHandlers()
  }

  var proto = SourceToDestination.prototype

  proto.nameToId = function (name) {
    return name.replace(/ /, '')
  }

  proto.firstRender = function () {
    this.template = JST[this.template]
    this.node.hide()
    this.node.html(
      this.template({
        names: this.names,
        pairings: [],
        identifiers: this.identifiers,
      })
    )
    this.inputs = $(
      $(this.names).map(
        $.proxy(function (pos, name) {
          return $('input[name="' + this.identifiers[pos] + '"]', this.node)[0]
        }, this)
      )
    )
    this.table = $('table', this.node)
    this.table.hide()
    this.node.show()
  }

  proto.addPairing = function (e) {
    if (e) {
      e.preventDefault()
    }
    this.table.show()
    this.pairings.push(this.inputsToPairing())
    this.resetInputs()
    this.renderTable(this)
  }

  proto.inputsToPairing = function () {
    return $(this.inputs)
      .toArray()
      .reduce(
        $.proxy(function (memo, input, pos) {
          memo[input.name] = $(this.inputs[pos]).val()
          return memo
        }, this),
        {}
      )
  }

  proto.resetInputs = function () {
    $(this.inputs).each(function (pos, node) {
      $(node).val('')
    })
  }

  proto.renderTable = function () {
    var allRender = this.template({
      pairings: this.pairings,
      names: this.names,
      identifiers: this.identifiers,
    })
    var containerTable = this.table.parent()
    containerTable.html($('table', allRender))
    this.table = $('table', containerTable)
  }

  proto.send = function () {
    this.dataParamsNode.val(JSON.stringify({ pairings: this.pairings }))
    this.node.trigger('rails.submit')
  }

  proto.readTabulatorHandler = function (e) {
    if (e.keyCode === 9 || e.keyCode === 13) {
      e.preventDefault()
    }
  }

  proto.nextInputHandler = function (e) {
    var nextInput = e.keyCode === 9 || e.keyCode == 13
    var sendInput = e.keyCode == 13
    if (nextInput) {
      e.preventDefault()

      var pos = this.inputs.index(e.target)
      if (pos >= 0) {
        if (pos === this.inputs.length - 1) {
          this.addPairing()
          this.inputs[0].focus()
        } else {
          this.inputs[pos + 1].focus()
        }
      }
    }
    return !nextInput
  }

  proto.buildHidden = function (tag, pos, role, value) {
    var hidden = document.createElement('input')
    $(hidden).attr('type', 'hidden')
    $(hidden).attr('name', [tag, '[', pos, '][', role, ']'].join(''))
    $(hidden).val(value)
    this.node.append(hidden)
  }

  proto.reset = function (e) {
    if (e) {
      e.preventDefault()
    }
    this.pairings = []
    this.renderTable()
    this.resetInputs()
  }

  proto.attachHandlers = function () {
    $(this.addButton).on('click', $.proxy(this.addPairing, this))
    $(this.sendbutton).on('click', $.proxy(this.send, this))
    $(this.resetButton).on('click', $.proxy(this.reset, this))
    $(this.node).on('keydown', this.inputs, $.proxy(this.readTabulatorHandler, this))
    $(this.node).on('keyup', this.inputs, $.proxy(this.nextInputHandler, this))
    //$(this.sourceInput).on('keydown', $.proxy(this.readTabulatorHandler, this));
    //$(this.destinationInput).on('keydown', $.proxy(this.readTabulatorHandler, this));
    //$(this.sourceInput).on('keyup', $.proxy(this.nextInputHandler, this));
    //$(this.destinationInput).on('keyup', $.proxy(this.nextInputHandler, this));
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      SourceToDestination: SourceToDestination,
    })
  })
})()
