# frozen_string_literal: true
require 'spec_helper'

def build_instance
  FactoryGirl.create(model.to_s.underscore.to_sym)
end

shared_examples_for 'deprecatable' do
  let(:model) { described_class }

  it 'deprecates all the instances of the class with the same name' do
    deprecatable_list = Array.new(10) { build_instance }

    expect(model.all.count).to eq(deprecatable_list.count)
    expect(model.visible.count).to eq(deprecatable_list.count)

    active_instance = build_instance

    deprecatable_list.each { |old| old.deprecate_with(active_instance) }

    expect(model.visible.count).to eq(1)
    expect(model.all.count).to eq(deprecatable_list.count + 1)
    expect(model.visible.first).to eq(active_instance)
  end
end
