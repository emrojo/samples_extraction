require 'rails_helper'

RSpec.describe UserSessionsController, type: :controller do
  context '#create' do
    let!(:user) { create(:user, barcode: '1234') }
    it 'creates a session' do
      post :create, params: { user_session: { barcode: '1234' } }, as: :json
      expect(session[:token]).not_to eq(nil)
    end
  end
  context '#destroy' do
    context 'when you are logged in' do
      before do
        session[:token] = 'mytoken'
        @user = create :user, token: session[:token]
      end
      it 'destroys the session' do
        post :destroy
        expect(session[:token]).to eq(nil)
        @user.reload
        expect(@user.token).to eq(nil)
      end
    end
    context 'when you are not logged in' do
      before { @user = create :user, token: 'mytoken' }
      it 'does not remove the token' do
        post :destroy
        expect(session[:token]).to eq(nil)
        @user.reload
        expect(@user.token).not_to eq(nil)
      end
    end
  end
end
