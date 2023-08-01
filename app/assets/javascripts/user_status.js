;(function ($, undefined) {
  var COOKIE_NAME = 'psd-samples-extraction-login'

  function UserStatus(node, params) {
    this.node = $(node)
    this.userServiceUrl = params.userServiceUrl
    this.usernameNode = $(params.usernameSelector, this.node)
    this.fullNameNode = $(params.fullNameSelector, this.node)
    this.controlLoggedOut = $(params.logoutSelector, this.node)
    this.controlLoggedIn = $(params.loginSelector, this.node)
    this.changeLoginNode = $(params.changeLoginSelector, this.node)
    this.roleNode = $(params.roleSelector, this.node)
    this.tubePrinterNode = $(params.tubePrinterSelector, this.node)
    this.platePrinterNode = $(params.platePrinterSelector, this.node)

    this.logoutButton = $('.logout', this.controlLoggedIn)

    this.attachHandlers()
    this.initialize(params)
  }

  var proto = UserStatus.prototype

  proto.initialize = function (params) {
    if (params.sessionInfo) {
      this.updateLogin(params.sessionInfo)
    } else {
      this.setCookie({})
    }
  }

  proto.login = function (data) {
    /*if (this.isLogged()) {
       this.logout();
        }*/
    this.updateLogin(data)
    this.setCookie(data)
    $(this.node).trigger('login.user_status', data)
  }

  proto.setUsername = function (name) {
    $(this.usernameNode).html(name)
  }

  proto.setFullName = function (fullName) {
    $(this.fullNameNode).html(fullName)
  }

  proto.setBarcode = function (barcode) {
    this.barcode = barcode
    //$('input[name=user_barcode]').val(barcode);
  }

  proto.setRole = function (role) {
    if (typeof this.role !== 'undefined') {
      $(document.body).removeClass(this.role + '-role')
      $(this.roleNode).html('')
    }

    if (typeof role === 'undefined') {
      return
    }
    this.role = role
    $(this.roleNode).html(this.role)
    $(document.body).addClass(this.role + '-role')
  }

  proto.setTubePrinter = function (tubePrinter) {
    var idx = $('#tube_printer_select option')
      .filter(function () {
        return $(this).html() == tubePrinter
      })
      .val()
    $('#tube_printer_select').val(idx)
    $(this.tubePrinterNode).html(tubePrinter)
  }

  proto.setPlatePrinter = function (platePrinter) {
    var idx = $('#plate_printer_select option')
      .filter(function () {
        return $(this).html() == platePrinter
      })
      .val()
    $('#plate_printer_select').val(idx)
    $(this.platePrinterNode).html(platePrinter)
  }

  proto.getBarcode = function () {
    return this.barcode
  }

  proto.updateLogin = function (data) {
    if (typeof data !== 'undefined') {
      this.setUsername(data.username)
      this.setFullName(data.fullname)
      this.setBarcode(data.barcode)
      this.setRole(data.role)
      this.setTubePrinter(data.tube_printer_name)
      this.setPlatePrinter(data.plate_printer_name)
    }

    var showStatus = typeof data !== 'undefined' && !!data.username
    this.controlLoggedOut.toggle(!showStatus)
    this.controlLoggedIn.toggle(showStatus)
    $(document.body).toggleClass('logged-off', !showStatus)
    $(document.body).toggleClass('logged-in', showStatus)
  }

  proto.logoutUrl = function () {
    return this.userServiceUrl.replace('create', 'delete')
  }

  proto.logout = function (e) {
    if (typeof e !== 'undefined') {
      e.preventDefault()
    }

    $.ajax({
      method: 'delete',
      cache: false,
      url: this.logoutUrl(),
      dataType: 'json',
      success: $.proxy(function () {
        this.resetBarcodeInput()
        this.val = this.getCookie()
        $(document.body).toggleClass('logged-in', false)
        var data = {}
        this.updateLogin(data)
        this.setCookie(data)
        $(this.node).trigger('logout.user_status', data)
      }, this),
    }).fail($.proxy(this.onUserServiceFail, this))
  }

  proto.getCookie = function () {
    var cookie = Cookies.get(COOKIE_NAME)
    if (cookie) {
      return JSON.parse(cookie)
    }
  }

  proto.setCookie = function (value) {
    return Cookies.set(COOKIE_NAME, JSON.stringify(value))
  }

  proto.isLogged = function () {
    return typeof this.getCookie() !== 'undefined' && typeof this.getCookie().username !== 'undefined'
  }

  proto.readUserBarcode = function (e, data) {
    e.stopPropagation()
    $(this.node).trigger('load_start.loading_spinner', {})
    $.ajax({
      method: 'post',
      cache: false,
      dataType: 'json',
      url: this.userServiceUrl,
      data: { user_session: data },
      dataType: 'json',
      success: $.proxy(this.onUserServiceSuccess, this),
    }).fail($.proxy(this.onUserServiceFail, this))
  }

  proto.resetBarcodeInput = function () {
    $('input[name=userBarcode]').val('')
  }
  proto.onUserServiceSuccess = function (response) {
    this.resetBarcodeInput()
    $(this.node).trigger('load_stop.loading_spinner', {})
    //$('.dropdown-toggle', this.node).dropdown('toggle');
    if (response && !!response.username) {
      this.login(response)
    } else {
      this.node.trigger('msg.display_error', { msg: 'User barcode not valid' })
    }
  }

  proto.onUserServiceFail = function () {
    this.resetBarcodeInput()
    this.node.trigger('msg.display_error', {
      msg: 'Cannot connect with user service',
    })
    $(this.node).trigger('load_stop.loading_spinner', {})
  }

  proto.attachHandlers = function () {
    $('#login-button').on('click', function (e) {
      e.preventDefault()
    })
    $(this.node).on('barcode.barcode_reader', $.proxy(this.readUserBarcode, this))
    $(document).on(
      'login.user_status',
      $.proxy(function (e, data) {
        this.updateLogin(data)
      }, this)
    )
    $(document).on(
      'logout.user_status',
      $.proxy(function () {
        this.updateLogin({})
      }, this)
    )

    $(this.logoutButton).on('click', $.proxy(this.logout, this))
  }

  $(document).trigger('registerComponent.builder', { UserStatus: UserStatus })
})(jQuery)
