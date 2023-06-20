require 'rails_helper'

RSpec.describe PrintersController, type: :controller do
  setup { @printer = FactoryBot.create :printer, { name: 'one' } }

  it 'should get index' do
    get :index
    assert_response :success
  end

  it 'should get new' do
    get :new
    assert_response :success
  end

  it 'should create printer' do
    expect { post :create, params: { printer: @printer.attributes } }.to change { Printer.count }.by(1)

    assert_redirected_to printer_path(assigns(:printer))
  end

  it 'should show printer' do
    get :show, params: { id: @printer }
    assert_response :success
  end

  it 'should get edit' do
    get :edit, params: { id: @printer }
    assert_response :success
  end

  it 'should update printer' do
    patch :update, params: { id: @printer, printer: @printer.attributes }
    assert_redirected_to printer_path(assigns(:printer))
  end

  it 'should destroy printer' do
    expect { delete :destroy, params: { id: @printer } }.to change { Printer.count }.by(-1)

    assert_redirected_to printers_path
  end
end
