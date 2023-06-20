;(function ($, undefined) {
  function AssetFacts(node, params) {
    this.factTemplate = JST['templates/fact']
    this.node = node
    this.title = $('[data-psd-condition-group-title]', node)
    this.facts = $('.facts', this.node)
    this.name = this.title.text()

    this.factsStore = []

    this.attachHandlers()

    $(this.node).trigger('registered.condition-group', {
      conditionGroup: this,
    })
    setTimeout(
      $.proxy(function () {
        this.initialize(params)
      }, this),
      0
    )
  }

  var proto = AssetFacts.prototype

  proto.initialize = function (facts) {
    if (typeof facts !== 'undefined') {
      for (var i = 0; i < facts.length; i++) {
        this.addFact(facts[i])
      }
    }
  }

  proto.addRenderedFact = function (node, renderedFact) {
    if ($('.fact', node).length === 0) {
      node.text('')
    }
    node.append(renderedFact)
  }

  proto.getName = function () {
    return this.name
  }

  proto.getFacts = function () {
    return this.factsStore
  }

  proto.getCheckFacts = function () {
    var checkFacts = []
    if (this.getCardinality() !== null) {
      checkFacts.push({
        actionType: 'checkFacts',
        predicate: 'maxCardinality',
        literal: '"""' + this.getCardinality() + '"""',
      })
    }
    return checkFacts
  }

  proto.getCardinality = function () {
    return $('[data-psd-condition-group-cardinality]', this.node).text()
  }

  proto.getActionFacts = function () {
    return this.factsStore.filter(function (fact) {
      return fact.actionType != 'checkFacts'
    })
  }

  proto.addFact = function (fact) {
    if (this.findFact(fact) >= 0) {
      $(this.node).trigger('msg.display_error', {
        msg: 'The fact provided is already present in the condition group',
      })
      return
    }
    fact.actionType = 'createAsset'
    this.factsStore.push(fact)
    var renderedFact = this.factTemplate(fact)
    this.addRenderedFact(this.facts, renderedFact)
    $(document).trigger('execute.builder')
  }

  proto.listenFactsHandler = function (event, fact) {
    this.addFact(fact)
  }

  proto.listenEditableHandler = function (event, data) {
    event.stopPropagation()
    if ($(data.node).data('psd-condition-group-title')) {
      $(this.node).trigger('changed-name.condition-group', {
        nameOld: this.name,
        nameNew: data.text,
      })
    }
  }

  proto.findFact = function (fact) {
    return this.factsStore.findIndex(function (storedFact) {
      return (
        fact.predicate === storedFact.predicate &&
        fact.object === storedFact.object &&
        fact.object_reference === storedFact.object_reference &&
        fact.actionType === storedFact.actionType
      )
    })
  }

  proto.updateName = function (nameOld, nameNew) {
    if (this.name === nameOld) {
      this.name = nameNew
    }
    $(this.factsStore).each(function (pos, fact) {
      if (fact.object === nameOld) {
        fact.object = nameNew
      }
    })
    $('.fact', this.node).each(function (pos, fact) {
      if ($(fact).data('psd-fact-object').toString() === nameOld) {
        $(fact).data('psd-fact-object', nameNew)
        $('.object', fact).html(nameNew)
      }
    })
  }

  proto.onDeletedFactIcon = function (e, data) {
    var pos = this.findFact({
      predicate: $(data.node).data('psd-fact-predicate').toString(),
      object: $(data.node).data('psd-fact-object').toString(),
      actionType: $(data.node).data('psd-fact-actionType').toString(),
    })
    if (pos >= 0) {
      this.factsStore.splice(pos, 1)
    }
  }

  proto.onChangeSelectionCheck = function (e, data) {
    this.selectAsset = data === 'open'
  }

  proto.isSelected = function () {
    return this.selectAsset
  }

  proto.attachHandlers = function () {
    $(this.node).on('fact.fact_reader', $.proxy(this.listenFactsHandler, this))
    $(this.node).on('updated-text.editable-text', $.proxy(this.listenEditableHandler, this))
    $(this.node).on('deleted_node.delete_icon', $.proxy(this.onDeletedFactIcon, this))
    $(this.node).on('value.button_switch', $.proxy(this.onChangeSelectionCheck, this))
  }

  $(document).ready(function () {
    $(document).trigger('registerComponent.builder', {
      AssetFacts: AssetFacts,
    })
  })
})(jQuery)
