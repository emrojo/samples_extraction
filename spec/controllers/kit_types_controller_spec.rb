require 'rails_helper'

RSpec.describe KitTypesController, type: :controller do
  setup do
    @activity_type = FactoryBot.create :activity_type, { name: 'Testing activity type' }
    @kit_type = FactoryBot.create :kit_type, { name: 'My Kit Type', activity_type: @activity_type }
  end

  it 'should get index' do
    get :index
    assert_response :success
  end

  it 'should get new' do
    get :new
    assert_response :success
  end

  it 'should create kit_type' do
    expect { post :create, params: { kit_type: @kit_type.attributes } }.to change { KitType.count }.by(1)

    assert_redirected_to kit_type_path(assigns(:kit_type))
  end

  it 'should show kit_type' do
    get :show, params: { id: @kit_type }
    assert_response :success
  end

  it 'should get edit' do
    get :edit, params: { id: @kit_type }
    assert_response :success
  end

  it 'should update kit_type' do
    patch :update, params: { id: @kit_type, kit_type: @kit_type.attributes }
    assert_redirected_to kit_type_path(assigns(:kit_type))
  end

  it 'should destroy kit_type' do
    expect { delete :destroy, params: { id: @kit_type } }.to change { KitType.count }.by(-1)

    assert_redirected_to kit_types_path
  end
end
