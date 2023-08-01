require 'rails_helper'

RSpec.describe StepTypesController, type: :controller do
  setup { @step_type = FactoryBot.create :step_type }

  it 'should get index' do
    get :index
    assert_response :success
  end

  it 'should get new' do
    get :new
    assert_response :success
  end

  it 'should create step_type' do
    expect { post :create, params: { step_type: { name: 'Test' } } }.to change { StepType.count }.by(1)

    assert_redirected_to step_type_url(StepType.last)
  end

  it 'should show step_type' do
    get :show, params: { id: @step_type }
    assert_response :success
  end

  it 'should get edit' do
    get :show, params: { id: @step_type }
    assert_response :success
  end

  it 'should update step_type' do
    patch :update, params: { id: @step_type, step_type: @step_type.attributes }
    assert_redirected_to step_type_url(@step_type)
  end

  it 'should update priority for step_type' do
    step_type = create :step_type
    expect do
      post :update, params: { id: step_type.id, step_type: step_type.attributes.merge({ priority: 10 }.as_json) }
    end.to change {
      step_type.reload
      step_type.priority
    }.to(10)
  end

  it 'should destroy step_type' do
    expect { delete :destroy, params: { id: @step_type } }.to change { StepType.count }.by(-1)

    assert_redirected_to step_types_url
  end

  context '#create' do
    let(:params) { { step_type: { name: 'My task' } } }
    it 'creates a new step type' do
      expect { post :create, params: params }.to change { StepType.all.count }.by(1)
    end
    it 'redirects to the step type url' do
      post :create, params: params
      expect(response.redirect?).to eq(true)
    end
  end
end
