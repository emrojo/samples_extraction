require 'rails/test_help'
require 'minitest/mock'
require "rack_session_access/capybara"


Given /skip/ do
  skip_this_scenario
end

When(/^I use the browser to enter in the application$/) do
  Rails.application.config.printing_disabled=true
  visit '/'
end

When(/^I go to the Instruments page$/) do
  visit '/instruments'
end


Then(/^show me the page$/) do
  save_and_open_page
end

Then(/^I should see the Instruments page$/) do
  page.should have_content("Instruments")
end

Given(/^I have the following label templates:$/) do |table|
  table.hashes.each do |label_template|
    FactoryGirl.create(:label_template, 
      name: label_template['Name'], 
      template_type: label_template['Type'], 
      external_id: label_template['External Id']
    )
  end  
end

Given(/^I have to process these tubes that are on my table:$/) do |table|
  # table is a Cucumber::MultilineArgument::DataTable
  table.hashes.each do |asset_info|
    facts = asset_info['Facts'].split(',').map do |f|
      l = f.split(':')
      FactoryGirl.create :fact, {:predicate => l[0].strip, :object => l[1].strip}
    end
    asset = FactoryGirl.create :asset, {:barcode => asset_info['Barcode'], :facts => facts}
  end
end


Given(/^I have the following kits in house$/) do |table|
  table.hashes.each do |kit_info|
    kit_type = KitType.find_by_name(kit_info["Kit type"])
    unless kit_type
      activity_type = ActivityType.find_by_name(kit_info["Activity type"])
      kit_type = FactoryGirl.create :kit_type, {
        :name =>kit_info["Kit type"],
        :activity_type => activity_type
      }
    end
    FactoryGirl.create :kit, { :barcode => kit_info["Barcode"], :kit_type => kit_type }
  end
end

When(/^I create an activity with instrument "([^"]*)" and kit "(\d+)"$/) do |instrument_name, kit_barcode|
  instrument = Instrument.find_by_name(instrument_name)
  visit instrument_path(instrument)
  fill_in 'Kit barcode', with: kit_barcode

  click_on('Create activity', :visible => false)
end

Given(/^we use these activity types:$/) do |table|
  table.hashes.each do |activity_type|
    FactoryGirl.create :activity_type, {:name => activity_type["Name"]}
  end
end

Given(/^we use these step types:$/) do |table|
  table.hashes.each do |step_type|
    activity_types = step_type["Activity types"].split(',').map do |activity_type_name|
      ActivityType.find_by_name(activity_type_name.strip)
    end
    FactoryGirl.create :step_type, {
      :name => step_type["Name"],
      :activity_types => activity_types
    }
  end
end

Given(/^the laboratory has the following instruments:$/) do |table|
  table.hashes.each do |instrument|
    activity_types = instrument["Activity types"].split(',').map do |activity_type_name|
      ActivityType.find_by_name(activity_type_name.strip)
    end
    FactoryGirl.create :instrument, {
      :barcode => instrument["Barcode"],
      :name => instrument["Name"],
      :activity_types => activity_types
    }
  end
end

Then(/^I should have created an empty activity for "([^"]*)"$/) do |arg1|
  activities = ActivityType.find_by_name(arg1).activities
  expect(activities.count).to eq(1)
  expect(activities.first.asset_group.assets.count).to eq(0)
end

When(/^I scan the barcode "([^"]*)" in the selection basket$/) do |barcode|
  fill_in('Scan a barcode', :with => barcode+"\n")
  click_on('Send barcode')
end

When(/^I scan these barcodes into the selection basket:$/) do |table|
  table.hashes.each do |barcode_info|
    step("I scan the barcode \"#{barcode_info["Barcode"]}\" in the selection basket")
    step("I should see the barcode \"#{barcode_info["Barcode"]}\" in the selection basket")
  end
  sleep 5
end

Then(/I should see the barcode "([^"]*)" in the selection basket$/) do |barcode|
  within('form.edit_asset_group') do
    if (page.has_content?("tr"))
      page.should have_content(barcode)
    end
  end
end

Then(/^I should see these barcodes in the selection basket:$/) do |table|
  table.hashes.each do |barcode|
    step("I should see the barcode \"#{barcode["Barcode"]}\" in the selection basket")
  end
end

Given(/^the step type "([^"]*)" has this configuration in N3:$/) do |step_type_name, n3_definition|
  step_type = StepType.find_by_name(step_type_name)
  step_type.update(:n3_definition => n3_definition)
end

Then(/^I should see these steps available:$/) do |table|
  within(".firststeptype .content_step_types") do
    table.hashes.each do |step_type|
      expect(page.has_button?(step_type["Step"])).to eq(true)
    end
  end
end

When(/^I perform the step "([^"]*)"$/) do |step_name|
  all('.firststeptype .step_types_active ul.step-selection li').select do |node|
    node['innerHTML'].include?(step_name)
  end.first.click
  sleep 5
end

Then(/^I should not have performed the step "([^"]*)"$/) do |step_name|
  within("#steps_finished .panel") do
    page.should have_no_content(step_name)
  end
end

Then(/^I should have performed the step "([^"]*)"$/) do |step_name|
  within("#steps_finished .panel") do
    page.should have_content(step_name)
  end
end

Then(/^I should ?(not)? have performed the step "([^"]*)" with the user "([^"]*)"$/) do |not_action, step_name, username|
  expect((Step.last.step_type.name == step_name) && (Step.last.user.username == username)).to eq(not_action != 'not')
end

When(/^I open the operations list$/) do
  find("#steps_finished").click
end

Then(/^I should ?(not)? have performed the step "([^"]*)" with the following barcodes:$/) do |not_action, step_name, table|
  # table is a Cucumber::MultilineArgument::DataTable
  within("#steps_finished .panel") do
    expect(page.has_content?(step_name)).to eq(not_action!='not')
    table.hashes.each do |h|
      expect(page.has_content?(h["Barcode"])).to eq(not_action!='not')
    end
  end
end

Then(/^I should see (\d+) elements? in the selection basket$/) do |num|
  expect(all('form.edit_asset_group tbody tr').length.to_s).to eq(num)
end

Then(/^I should see a "([^"]*)" in the selection basket$/) do |type|

  result = page.find('form.edit_asset_group').has_content?(type)
  unless result
    result = page.find('form.edit_asset_group').has_content?(type)
  end
  expect(result).to eq(true)

  #expect(page.find('form.edit_asset_group tbody').has_content?(type)).to eq(true)
  #expect(all('form.edit_asset_group tbody tr').length.to_s).to eq(num)
end

Then(/^I should not see any steps available$/) do
  expect(all(".firststeptype .content_step_types li").length).to eq(0)
end

When(/^I finish the activity$/) do
  expect(page.has_content?("Finish activity?"))
  click_on('Finish activity?')
end

Then(/^the activity should be finished$/) do
  expect(page.has_content?("This activity was finished")).to eq(true)
end

When(/^I want to export a plate to Sequencescape$/) do
  class MockBarcode
    def ean13
      'barcode'
    end
  end
  class MockSequencescapePlateInstance
    attr_accessor :uuid, :barcode

    def initialize
      @uuid = 'uuid'
      @barcode = MockBarcode.new
    end

    def wells
      []
    end
  end
  class SequencescapeClient
    def self.find_by_uuid(uuid)
      MockSequencescapePlateInstance.new
    end
    def self.create_plate(name, opts)
      MockSequencescapePlateInstance.new
    end
    def self.update_extraction_attributes(instance, attrs, user)
      MockSequencescapePlateInstance.new
    end
  end

end

When(/^I want to print "([^"]*)" new barcodes starting from "([^"]*)" with template "([^"]*)" at printer "([^"]*)"$/) do |num_barcodes, barcode_start, template_name, printer_name|
  template = LabelTemplate.find_by_name(template_name)
  PMB::PrintJob = MiniTest::Mock.new
  username = @user.username
  Rails.application.config.printing_disabled=false
  class TestA
    def save
      true
    end
  end

  class Asset
    @@testing_barcode = nil
    @@username = nil
    def self.init_testing(barcode_start, username)
      @@testing_barcode = barcode_start.to_i
      @@username = username
    end

    def self.testing_barcode
      @@testing_barcode
    end

    def generate_barcode(i)
      update_attributes(:barcode => Barcode.calculate_barcode(Rails.application.config.barcode_prefix,Asset.testing_barcode+i)) if barcode.nil?
    end

    def printable_object(username='unknown')
      Asset.printable_object(username)
    end

    def self.printable_object(username)
      {
        :label => {
          :testing_param => @@testing_barcode,
          :username => username
        }
      }
    end
  end

  Asset.init_testing(barcode_start, username)

  body = num_barcodes.to_i.times.map do |b|
    Asset.printable_object(username)
  end

  PMB::PrintJob.expect(:new, TestA.new, [{:printer_name=>printer_name,
   :label_template_id => template.external_id, :labels=>{:body=>body}}])
end

Then(/^I should have printed what I expected$/) do
  PMB::PrintJob.verify
end


Then(/^I should ?(not)? have created an asset with the following facts:$/) do |not_action, table|
  table.hashes.each do |h|
    if not_action!='not'
      expect(page.has_content?(h["Predicate"])).to eq(not_action!='not')
      expect(page.has_content?(h["Object"])).to eq(not_action!='not')
    end
    expect(Asset.last.has_literal?(h["Predicate"], h["Object"])).to eq(not_action!='not')
  end
end
