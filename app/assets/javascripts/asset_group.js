(function($, undefined) {

  function AssetGroup(node) {
    var node = $(node);
    this.container = $('#asset-group-container');//node.parent();
    this.form = node;
    //this.identifier = $(node).attr("data-psd-asset-group-form");
    this.content = $('[data-psd-asset-group-content]', node);
    //this.template = JST['templates/asset_group'];
    this.attachHandlers(node);
    this.actualTimestamp = null;

    this.init();
  };

  var proto = AssetGroup.prototype;

  proto.init = function() {
    $.get({url: $('#asset-group-container form').attr('action')});
  };

  proto.onRemoveBarcode = function(barcode) {

  };

  proto.onAddBarcode = function(barcode) {

  };

  proto.focusToAddBarcode = function() {
    $('input#asset_group_add_barcode', this.form).focus();
  };

  proto.render = function(json) {
    $('.asset-group-content', this.container).html(json);
    this.form = $('form', this.container);
    this.attachHandlers(this.form);
    this.reloadStepTypes();
    this.reloadSteps();
    this.focusToAddBarcode();
    //this.content.html(json);
    //this.attachDeleteButtons(this.content);
  };

  proto.attachDeleteButtons = function(node) {
    $('[data-psd-asset-group-delete-all-barcodes]', node).on('click', $.proxy(function(e) {
      $(e.target).addClass('disabled');
      $('input#asset_group_delete_all_barcodes', this.form).val('true');
    }));
    $('[data-psd-asset-group-delete-barcode]', node).on('click', $.proxy(function(e) {
        $(e.target).addClass('disabled');
      //if (!((e.screenX==0) && (e.screenY==0))) {
        // Yes, I know...
        $('input#asset_group_delete_barcode', this.form).val($(e.target).attr('data-psd-asset-group-delete-barcode'));
      //}
    }, this));
  };

  proto.cleanInput = function() {
    $('input#asset_group_add_barcode', this.form).val('');
    $('input#asset_group_delete_barcode', this.form).val('');
  };

  proto.reloadStepTypes = function() {
    var url = $('.step_types_active').data('psd-step-types-update-url');
    $('.step_types_active').load(url, $.proxy(function() {
      $(this.form).trigger("execute.builder");
    }, this));

    $(this.form).trigger("execute.builder");
  };

  proto.reloadSteps = function() {
    var url = $('#steps_finished > div').data('psd-steps-update-url');
    $('#steps_finished').load(url, $.proxy(function() {
      $(this.form).trigger("execute.builder");
    }, this));
  };

  proto.onAssetGroupChange = function() {
    if (!this.loadInProgress) {
      this.loadInProgress=true;

      this.reloadStepTypes();
      this.reloadSteps();
      this.loadInProgress=false;
    }
  };


  proto.attachHandlers = function(node) {
    this.attachDeleteButtons(node);

    

    $(this.form).on('submit.rails', function() {
      var node;
      node = $(".step_types_active .panel-body .content_step_types");
      node.trigger("load_start.loading_spinner", {
        node: node
      });
      node = $("#steps_finished .panel-body .steps-table");
      node.trigger("load_start.loading_spinner", {
        node: node
      });
    });

    $('input#asset_group_add_barcode', node).on('keydown', $.proxy(function(e) {
      if (e.keyCode === 9) {
        // Default behaviour of Tabulator is to change to the next input before keyup event; we
        // customized this behaviour to perform a submit Rails-way instead
        this.form.trigger('submit.rails');
        e.preventDefault();
      }
    }, this));


    $(node).on('asset_group.changed', $.proxy(this.onAssetGroupChange, this));

    $(node).on('ajax:success', $.proxy(function(e, json, r) {
      this.render(json);
    }, this)).on('ajax:send', $.proxy(function(r) {
      this.cleanInput();
    }, this)).on('ajax:complete', $.proxy(this.onAssetGroupChange, this));
  };

  $(document).ready(function() {
    //new AssetGroup($('[data-psd-asset-group-form]'));
    $(document).trigger('registerComponent.builder', {'AssetGroup': AssetGroup});
  });
}(jQuery));
