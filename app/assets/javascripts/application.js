// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require js.cookie
//= require_tree .
//= require bootstrap-sprockets
//= require dropzone
//= require action_cable
//= require turbolinks

//= require component_builder
//= require asset_facts
//= require barcode_reader
//= require condition_groups
//= require condition_group
//= require delete_icon
//= require display_error
//= require editable_text
//= require fact_searcher_lightweight
//= require loading_icon
//= require rack_well_display
//= require source_to_destination
//= require button_switch
//= require fact_reader
//= require finish_step_button
//= require user_status
//= require add_fact_to_searchbox
//= require tube_into_rack
//= require ace-rails-ap
//= require step_cancellable
//= require_tree ./templates
//= require_tree .
//    require_asset "peek"
//    require_asset "peek/views/performance_bar"

window.App = {}
window.App.cable = ActionCable.createConsumer()
