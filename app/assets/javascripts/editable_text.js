;(function ($, undefined) {
  function EditableText(node) {
    this.node = $(node)
    this.template = JST['templates/editable_text']
    this.node.addClass('editable-text')
    this.textWhenEmpty = 'None'

    if ($(this.node).text().length === 0) {
      $(this.node).html(this.textWhenEmpty)
    }
    this.attachHandlers()
  }

  var proto = EditableText.prototype

  proto.restoreContent = function () {
    //this.contents.html(this.getTextFromEditor());
    if (this.contents === null) {
      return
    }
    if (this.validatesContent()) {
      var text = this.getTextFromEditor()
      if (text.length === 0) {
        text = this.textWhenEmpty
      }
      $(this.node).html(text)
      $(this.node).trigger('updated-text.editable-text', {
        text: this.getTextFromEditor(),
        node: this.node,
        oldText: this.contents.text(),
      })
    } else {
      $(this.node).html(this.contents)
      $(document).trigger('msg.display_error', {
        msg: 'The supplied text should follow the pattern:' + $(this.node).data('psd-editable-text-regexp'),
      })
    }

    this.contents = null
    this.attachEditor()
  }

  proto.validatesContent = function () {
    var regexp = $(this.node).data('psd-editable-text-regexp')
    if (regexp) {
      return !!this.getTextFromEditor().match(new RegExp(regexp))
    }
    return true
  }

  proto.attachEditor = function () {
    $(this.node).one('click', $.proxy(this.addEditor, this))
  }

  proto.getTextFromEditor = function () {
    return this.editor.val()
  }

  proto.specialKeysHandler = function (e) {
    this.resizeEditor()
    if (e.keyCode === 9) {
      this.restoreContent()
      e.preventDefault()
    }
    if (e.keyCode == 13) {
      this.restoreContent()
      e.preventDefault()
    }
  }

  proto.setInputFocus = function () {
    $(this.editor).focus()
    this.editor[0].selectionStart = this.editor[0].selectionEnd = this.editor[0].value.length
  }

  proto.addEditor = function (event) {
    if ($(this.node).parents('.readonly').length != 0) {
      this.attachEditor()
      return
    }

    var text = $(this.node).text()
    if (text === this.textWhenEmpty) {
      text = ''
    }
    var editorRendered = this.template({ text: text })
    this.contents = $(this.node).contents()
    $(this.node).html(editorRendered)

    this.editor = $('input', this.node)
    this.editor.on('blur', $.proxy(this.restoreContent, this))
    this.editor.on('keydown', $.proxy(this.specialKeysHandler, this))
    this.resizeEditor()
    this.setInputFocus()
  }

  proto.resizeEditor = function () {
    $(this.editor).attr('size', $(this.editor).val().length + 1)
  }

  proto.attachHandlers = function () {
    this.attachEditor()
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      EditableText: EditableText,
    })
  })
})(jQuery)
