# frozen_string_literal: true
require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  setup do
    @controller = UserSessionsController.new
    @barcode = 1
    @user = FactoryGirl.create :user, barcode: @barcode
    @request.headers['Accept'] = Mime::JSON
    @request.headers['Content-Type'] = Mime::JSON.to_s
  end

  test 'create a new session' do
    @user.reload
    assert_equal true, @user.token.nil?
    post :create, user_session: { barcode: @barcode }
    @user.reload
    assert_equal false, @user.token.nil?
  end

  test 'remove a session' do
    post :create, user_session: { barcode: @barcode }
    @user.reload
    assert_equal false, @user.token.nil?
    delete :destroy, id: @user.id
    @user.reload
    assert_equal true, @user.token.nil?
  end
end
