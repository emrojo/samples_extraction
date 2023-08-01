;(function () {
  var POS = 0

  function ConditionGroups(node, params) {
    this.template = JST['templates/condition_group']
    this.node = $(node)
    this.button = $('[data-psd-condition-group-action-types]', this.node)
    this.buttonNewAsset = $('[data-psd-asset-facts-action-types]', this.node)
    this.conditionGroups = []
    this.attachHandlers()

    if (params) {
      setTimeout(
        $.proxy(function () {
          this.initializeConditionGroups(params)
        }, this),
        0
      )
    }
  }

  var proto = ConditionGroups.prototype

  proto.assetFactsTemplate = function () {
    return JST['templates/asset_facts']
  }

  proto.initializeConditionGroups = function (params) {
    for (var key in params) {
      var template = this.template
      if (params[key].template) {
        template = JST[params[key].template]
      }
      if (
        params[key].facts.find(function (f) {
          return f.actionType === 'createAsset'
        })
      ) {
        template = this.assetFactsTemplate()
      }
      this.addGroup(key, params[key], template)
    }
  }

  proto.addGroup = function (name, params, template) {
    var template = template || this.template
    var conditionGroup = template({
      name: name,
      cardinality: params.cardinality || 0,
      keepSelected: !!params.keepSelected,
      actionTypes: this.button.data('psd-condition-group-action-types') || [],
      facts: JSON.stringify(params.facts),
    })
    $('#conditionGroups').append(conditionGroup)
    $(document).trigger('execute.builder')
  }

  proto.generateGroupName = function () {
    POS = POS + 1
    return 'Condition' + POS
  }

  proto.generateAssetName = function () {
    POS = POS + 1
    return 'Asset' + POS
  }

  proto.checkFactToN3 = function (group, fact) {
    return (
      ['?' + group.getName(), ':' + fact.predicate, fact.object ? '"""' + fact.object + '"""' : fact.literal].join(
        '\t '
      ) + ' .'
    )
  }

  proto.actionFactToN3 = function (group, fact) {
    return ':step\t :' + fact.actionType + '\t {' + this.checkFactToN3(group, fact) + '} .\n'
  }

  proto.getStepTypeName = function () {
    return $('div.step_type_name input', this.node).val()
  }

  proto.getStepTemplate = function () {
    return $('#step_type_step_template').val()
  }

  proto.stepTypeToN3 = function () {
    return ':step\t :stepTypeName """' + this.getStepTypeName() + '""" .\n'
  }

  proto.stepTemplateToN3 = function () {
    if (this.getStepTemplate().length > 0) {
      return '\t:step\t :stepTemplate """' + this.getStepTemplate() + '""" .\n'
    } else {
      return ''
    }
  }

  proto.stepTypeConfigToN3 = function () {
    return this.stepTypeToN3() + this.stepTemplateToN3()
  }

  proto.renderRuleN3 = function (n3Checks, n3Actions, n3Selects) {
    return '{\n\t' + n3Checks + '\n} => {\n\t' + this.stepTypeConfigToN3() + n3Selects + '\t' + n3Actions + '} .\n'
  }

  proto.toN3 = function (e) {
    if (this.conditionGroups.length == 0) {
      return ''
    }
    var checksN3 = $.map(
      this.conditionGroups,
      $.proxy(function (group) {
        return $.map(group.getCheckFacts(), $.proxy(this.checkFactToN3, this, group))
      }, this)
    ).join('\n\t')

    var actionsN3 = $.map(
      this.conditionGroups,
      $.proxy(function (group) {
        return $.map(group.getActionFacts(), $.proxy(this.actionFactToN3, this, group))
      }, this)
    ).join('\t')

    var selectsN3 = $.map(
      this.conditionGroups,
      $.proxy(function (group) {
        if (!group.isSelected()) {
          return '\t:step\t :unselectAsset\t ?' + group.name + '.\n'
        } else {
          return ''
        }
      })
    ).join('')

    var n3 = this.renderRuleN3(checksN3, actionsN3, selectsN3)

    //$(this.node).trigger('msg.display_error', {msg: n3});

    return n3
  }

  proto.storeN3 = function (e) {
    var n3 = this.toN3()
    if (n3.length > 0) {
      $('input#step_type_n3_definition').val(n3)
    }
    //alert(this.toN3());
  }

  proto.storeConditionGroup = function (e, data) {
    this.conditionGroups.push(data.conditionGroup)
  }

  proto.destroyConditionGroup = function (e, data) {
    var pos = this.conditionGroups.indexOf(data.conditionGroup)
    if (pos > -1) {
      this.conditionGroups.splice(pos, 1)
    }
  }

  proto.updateConditionGroupName = function (e, data) {
    $(this.conditionGroups).each(function (pos, conditionGroup) {
      conditionGroup.updateName(data.nameOld, data.nameNew)
    })
  }

  proto.showEditor = function () {
    var editor = ace.edit('editor')
    editor.setTheme('ace/theme/monokai')
    editor.getSession().setMode('ace/mode/text')

    if ($('input#step_type_n3_definition').val().length == 0) {
      editor.setValue(this.toN3())
    } else {
      editor.setValue($('input#step_type_n3_definition').val())
    }
  }

  proto.getEditorContent = function () {
    var editor = ace.edit('editor')
    //editor.setTheme("ace/theme/monokai");
    //editor.getSession().setMode("ace/mode/text");
    return editor.getValue()
  }

  proto.hideEditor = function () {
    //$('#editorContainer').hide();
  }

  proto.onChangeForReasoning = function () {
    var node = $('#step_type_for_reasoning')[0]
    if (node) {
      //$('.edit_step_type').toggleClass('for-reasoning', node.checked);
    }
  }

  proto.attachHandlers = function () {
    this.onChangeForReasoning()

    $(this.button).on(
      'click',
      $.proxy(function () {
        this.addGroup(this.generateGroupName(), {})
      }, this)
    )
    $(this.buttonNewAsset).on(
      'click',
      $.proxy(function () {
        this.addGroup(this.generateAssetName(), {}, this.assetFactsTemplate())
      }, this)
    )
    $(this.node).on('registered.condition-group', $.proxy(this.storeConditionGroup, this))
    $(this.node).on('destroyed.condition-group', $.proxy(this.destroyConditionGroup, this))
    $(this.node).on('changed-name.condition-group', $.proxy(this.updateConditionGroupName, this))

    $('[data-psd-condition-groups-save]').on('click', $.proxy(this.storeN3, this))

    $('#step_type_for_reasoning').on('click', $.proxy(this.onChangeForReasoning, this))
    $('.show-n3').on(
      'click',
      $.proxy(function (e) {
        //e.stopPropagation();
        e.preventDefault()
        this.showEditor()
        //return false;
      }, this)
    )
    $('.update-n3').on(
      'click',
      $.proxy(function (e) {
        if (this.getEditorContent().length > 0) {
          $('input#step_type_n3_definition').val(this.getEditorContent())
        }
      }, this)
    )
  }

  $(document).trigger('registerComponent.builder', {
    ConditionGroups: ConditionGroups,
  })
})()
