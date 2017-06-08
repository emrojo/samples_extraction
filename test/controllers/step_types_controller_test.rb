# frozen_string_literal: true
require 'test_helper'

class StepTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @step_type = FactoryGirl.create :step_type
  end

  test 'should get index' do
    get step_types_url
    assert_response :success
  end

  test 'should get new' do
    get new_step_type_url
    assert_response :success
  end

  test 'should create step_type' do
    assert_difference('StepType.count') do
      post step_types_path, step_type: { name: 'Test' }
    end

    assert_redirected_to step_type_url(StepType.last)
  end

  test 'should show step_type' do
    get step_type_url(@step_type)
    assert_response :success
  end

  test 'should get edit' do
    get edit_step_type_url(@step_type)
    assert_response :success
  end

  test 'should update step_type' do
    patch step_type_url(@step_type), step_type: @step_type.attributes
    assert_redirected_to step_type_url(@step_type)
  end

  test 'should destroy step_type' do
    assert_difference('StepType.count', -1) do
      delete step_type_url(@step_type)
    end

    assert_redirected_to step_types_url
  end
end
