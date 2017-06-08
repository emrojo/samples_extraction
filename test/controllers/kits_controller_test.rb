# frozen_string_literal: true
require 'test_helper'

class KitsControllerTest < ActionController::TestCase
  setup do
    @kit_type = FactoryGirl.create :kit_type
    @kit = FactoryGirl.create :kit, kit_type: @kit_type
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:kits)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create kit' do
    assert_difference('Kit.count') do
      post :create, kit: @kit.attributes
    end

    assert_redirected_to kit_path(assigns(:kit))
  end

  test 'should show kit' do
    get :show, id: @kit
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @kit
    assert_response :success
  end

  test 'should update kit' do
    patch :update,  id: @kit, kit: @kit.attributes
    assert_redirected_to kit_path(assigns(:kit))
  end

  test 'should destroy kit' do
    assert_difference('Kit.count', -1) do
      delete :destroy, id: @kit
    end

    assert_redirected_to kits_path
  end
end
