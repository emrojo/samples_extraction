require 'rails_helper'

RSpec.describe 'Activities::State' do
  let(:activity) { create :activity }
  context 'when finishing an activity' do
    it 'changes the state to finish' do
      expect{activity.finish}.to change{activity.state}.to('finish')
    end
    it 'sets up a completion date' do
      expect{activity.finish}.to change{activity.completed_at}.from(nil)
    end
  end
end
