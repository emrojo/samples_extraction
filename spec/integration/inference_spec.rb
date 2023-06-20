require 'rails_helper'
require 'inferences_helper'
require 'integration/inferences_data'

def cwm_engine?
  Rails.configuration.inference_engine == :cwm
end

RSpec.describe 'Inference' do
  describe '#inference' do
    describe '#parse_facts' do
      it 'creates assets from a N3 definition', testcreation: true do
        code =
          '
          :tube1 :relates :tube2 .
          :tube2 :name """a name""" .
          :tube2 :volume """17""" .
        '

        obtained_assets = SupportN3.parse_facts(code)

        f1 = [
          FactoryBot.create(:fact, { predicate: 'name', object: 'a name' }),
          FactoryBot.create(:fact, { predicate: 'volume', object: '17' })
        ]
        tube2 = FactoryBot.create(:asset, name: 'tube2', facts: f1)
        f2 = [FactoryBot.create(:fact, { predicate: 'relates', object_asset: tube2 })]
        tube1 = FactoryBot.create(:asset, name: 'tube1', facts: f2)
        tube3 = FactoryBot.create(:asset)
        f3 = [FactoryBot.create(:fact, { predicate: 'relates', object_asset: tube2 })]
        tube4 = FactoryBot.create(:asset, name: 'tube4', facts: f3)
        f4 = [FactoryBot.create(:fact, { predicate: 'volume', object: '17' })]
        tube5 = FactoryBot.create(:asset, name: 'tube2', facts: f4)

        obtained_assets.each do |t|
          t.reload
          t.facts.reload
        end

        assets_are_equal([tube1], [tube1])
        assets_are_equal([tube1, tube2], obtained_assets)
        assets_are_different([tube3, tube2], obtained_assets)
        assets_are_different([tube4, tube2], obtained_assets)
        assets_are_different([tube1, tube5], obtained_assets)
        assets_are_equal([tube2, tube1], [tube1, tube2])

        assets_are_equal([tube1, tube1, tube2], [tube1, tube2])
      end
    end

    describe '#inferences' do
      before do
        # TODO
        # This workaround is just for the createAsset test. Refactor candidate
        allow(SecureRandom).to receive(:uuid).and_return('tube')
      end
      inferences_data.each do |data|
        if data[:unless]
          next if send(data[:unless])
        end

        if data[:it]
          tags = data[:tags] ? data[:tags] : {}
          it data[:it], tags do
            check_inference(data[:rule], data[:inputs], data[:outputs])
          end
        else
          xit data[:xit] do
            check_inference(data[:rule], data[:inputs], data[:outputs])
          end
        end
      end
    end
  end
end
