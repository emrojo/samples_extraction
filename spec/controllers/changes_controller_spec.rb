require 'rails_helper'

RSpec.describe ChangesController, type: :controller do
  context '#create' do
    it 'creates and performs the changes when providing fact_changes' do
      expect do
        post :create, params: { changes: { create_assets: ['?p'], add_facts: [%w[?p a Tube]] } }, as: :json
      end.to change { Step.all.count }.and change { Asset.all.count }.by(1)
      change = JSON.parse(response.body)
      expect(change['assets'].count).to eq(1)
      expect(change['assets'][0]['uuid']).not_to eq(nil)
    end
  end
end
