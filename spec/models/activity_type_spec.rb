# frozen_string_literal: true
require 'spec_helper'
require Rails.root.join 'spec/concerns/deprecatable_spec.rb'

describe ActivityType do
  it_behaves_like 'deprecatable'
end
