require 'rails_helper'

RSpec.describe ActivityTypesController, type: :controller do
  setup { @activity_type = FactoryBot.create :activity_type }

  it 'should get index' do
    get :index
    assert_response :success
  end

  it 'should get new' do
    get :new
    assert_response :success
  end

  it 'should create activity_type' do
    expect { post :create, params: { activity_type: @activity_type.attributes } }.to change { ActivityType.count }.by(1)

    assert_redirected_to activity_type_path(assigns(:activity_type))
  end

  it 'should show activity_type' do
    get :show, params: { id: @activity_type }
    assert_response :success
  end

  it 'should get edit' do
    get :edit, params: { id: @activity_type }
    assert_response :success
  end

  it 'should update activity_type' do
    patch :update, params: { id: @activity_type, activity_type: @activity_type.attributes }
    assert_redirected_to activity_type_path(assigns(:activity_type))
  end

  it 'should destroy activity_type' do
    expect { delete :destroy, params: { id: @activity_type } }.to change { ActivityType.count }.by(-1)

    assert_redirected_to activity_types_path
  end
end
