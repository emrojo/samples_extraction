require 'rails_helper'
RSpec.describe Action, type: :model do
  context '#each_connected_asset' do
    let(:action) { create(:action, step_type: step_type, predicate: 'some verb', action_type: 'something') }

    shared_examples 'a connector by position' do
      let(:step_type) { create(:step_type, connect_by: 'position') }
      it 'yields sources and destination' do
        i = 0
        action.each_connected_asset(sources, destinations) do |a, b|
          expect([a, b]).to eq(pairs_by_position[i])
          i = i + 1
        end
      end
    end
    shared_examples 'a connector of all to all' do
      let(:step_type) { create(:step_type) }
      it 'yields sources and destination' do
        i = 0
        action.each_connected_asset(sources, destinations) do |a, b|
          expect([a, b]).to eq(pairs[i])
          i = i + 1
        end
      end
    end

    context 'when there are equal number of sources and destinations' do
      let(:sources) { %i[a b c] }
      let(:destinations) { %i[alpha beta gamma] }
      let(:pairs_by_position) { [%i[a alpha], %i[b beta], %i[c gamma]] }
      let(:pairs) do
        [
          %i[a alpha],
          %i[a beta],
          %i[a gamma],
          %i[b alpha],
          %i[b beta],
          %i[b gamma],
          %i[c alpha],
          %i[c beta],
          %i[c gamma]
        ]
      end

      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
    context 'when there are less sources than destinations' do
      let(:sources) { %i[a b] }
      let(:destinations) { %i[alpha beta gamma] }
      let(:pairs_by_position) { [%i[a alpha], %i[b beta]] }
      let(:pairs) { [%i[a alpha], %i[a beta], %i[a gamma], %i[b alpha], %i[b beta], %i[b gamma]] }
      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
    context 'when there are less destinations than sources' do
      let(:sources) { %i[a b c] }
      let(:destinations) { %i[alpha beta] }
      let(:pairs_by_position) { [%i[a alpha], %i[b beta]] }
      let(:pairs) { [%i[a alpha], %i[a beta], %i[b alpha], %i[b beta], %i[c alpha], %i[c beta]] }
      it_behaves_like 'a connector by position'
      it_behaves_like 'a connector of all to all'
    end
  end
end
