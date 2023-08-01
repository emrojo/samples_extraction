;(function () {
  var STATUS_CLASSES = {
    editing: 'editing',
    edited: 'edited',
    info: 'info',
    error: 'error',
  }

  function TubeIntoRack(node, params) {
    this.node = $(node)
    this.params = params
    this.maxRow = params.maxRow || 8
    this.maxColumn = params.maxColumn || 12
    this.locationPos = 0
    this.racking = {}

    this.resetButton = $('button.reset-button', this.node)
    this.barcodeInput = $('input[name=tube_barcode]', this.node)
    this.locationDescription = $('.location-description', this.node)
    this.attachHandlers()

    this.resetRack()
    this.initializeParams(params)
    this.renderTable()
  }
  var proto = TubeIntoRack.prototype

  proto.getLocationFromCell = function (cell) {
    return $(cell)
      .attr('class')
      .split(' ')
      .filter(function (classname) {
        return classname.match(/[A-Z]\d*/)
      })[0]
  }

  proto.resetRack = function () {
    $('svg ellipse', this.node).each(
      $.proxy(function (pos, cell) {
        var locationPos = this.locationToPos(this.getLocationFromCell(cell))
        $(cell).on('click', $.proxy(this.modifyCell, this, locationPos + 1))
        this.cleanCellCss(cell)
      }, this)
    )
    this.racking = {}
    this.renderTable()
  }

  proto.cleanCellCss = function (cell) {
    for (var key in STATUS_CLASSES) {
      $(cell).removeClass(STATUS_CLASSES[key])
    }
  }

  proto.setEditingAtLocation = function (location) {
    $('ellipse', this.node).removeClass(STATUS_CLASSES.editing)
    $('ellipse.' + location).addClass(STATUS_CLASSES.editing)
    this.locationDescription.text(location)
  }

  proto.initializeParams = function (params) {
    if (typeof params.racking !== 'undefined') {
      for (var key in params.racking) {
        this.setCell(key, params.racking[key])
      }
      if (typeof params.error_params !== 'undefined') {
        $.each(
          params.error_params,
          $.proxy(function (pos, v) {
            $('.' + v, this.node).addClass(STATUS_CLASSES.error)
          }, this)
        )
      }
    }
    this.modifyCell(1)
    this.renderTable()
  }

  proto.nextLocation = function () {
    this.locationPos += 1
    return this.locationName(this.locationPos)
  }

  proto.locationName = function (locationPos) {
    var firstCharcode = 'A'.charCodeAt(0)
    var length = this.maxRow
    var desc_letter = String.fromCharCode(((locationPos - 1) % length) + firstCharcode)
    var desc_number = Math.floor((locationPos - 1) / length) + 1
    return desc_letter + desc_number
  }

  proto.renderTable = function () {
    var list = []
    for (var key in this.racking) {
      list = list.concat(['<tr class="', key, '""><td>', key, '</td><td>', this.racking[key], '</td></tr>'])
    }
    $('table tbody', this.node).html(list.join(''))
  }

  proto.readBarcode = function (e, data) {
    var cell = this.editNextCell(data.barcode)

    this.renderTable()
  }

  proto.setCell = function (location, barcode) {
    var oldLocation = this.locationPos
    this.locationPos = this.locationToPos(location)
    this.editNextCell(barcode)
    this.locationPos = oldLocation
  }

  proto.locationToPos = function (location) {
    return (parseInt(location.substring(1), 10) - 1) * this.maxRow + (location[0].charCodeAt() - 'A'.charCodeAt())
  }

  proto.editNextCell = function (barcode) {
    if (this.locationPos >= this.maxColumn * this.maxRow) {
      return
    }
    var location = this.nextLocation()
    this.racking[location] = barcode
    var cell = $('.' + location, this.node)

    this.cleanCellCss(cell)

    if (barcode.length !== 0) {
      cell.addClass(STATUS_CLASSES.edited)
    }
    cell.removeClass(STATUS_CLASSES.editing)
    var nextCellLocation = this.locationName(this.locationPos + 1)
    var nextCell = $('.' + nextCellLocation, this.node)
    nextCell.addClass(STATUS_CLASSES.editing)

    this.locationDescription.text(nextCellLocation)

    cell.off('click')
    cell.on('click', $.proxy(this.modifyCell, this, this.locationPos))

    nextCell.off('click')
    nextCell.on('click', $.proxy(this.modifyCell, this, this.locationPos + 1))
    return cell
  }

  proto.modifyCell = function (locationPos) {
    $('ellipse', this.node).removeClass(STATUS_CLASSES.editing)
    $('table tbody tr', this.node).removeClass(STATUS_CLASSES.info)
    this.locationPos = locationPos - 1
    var locationName = this.locationName(locationPos)
    this.barcodeInput.val(this.racking[locationName])
    this.locationDescription.text(locationName)

    $('table tbody tr.' + locationName, this.node).addClass(STATUS_CLASSES.info)
    $('.' + this.locationName(locationPos), this.node).addClass(STATUS_CLASSES.editing)
  }

  proto.attachHandlers = function () {
    this.node.on('barcode.barcode_reader', $.proxy(this.readBarcode, this))
    this.resetButton.on('click', $.proxy(this.resetRack, this))
    this.node.on('submit', $.proxy(this.prepareRackContent, this))
  }

  proto.prepareRackContent = function () {
    $('#step_data_action', this.node).val('racking')
    $('#step_data_params', this.node).val(JSON.stringify({ racking: this.racking }))
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      TubeIntoRack: TubeIntoRack,
    })
  })
})(jQuery)
