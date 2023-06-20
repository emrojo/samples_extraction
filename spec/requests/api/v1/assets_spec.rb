require 'rails_helper'

RSpec.describe 'Api::V1::Sets', type: :request do
  let(:headers) { { 'Content-Type' => 'application/vnd.api+json', 'Accept' => 'application/vnd.api+json' } }

  def key_for_attribute(attr_key)
    # Because some Traction attributes has been stored with a different predicate in extraction
    return :sample_common_name if attr_key == :species

    return attr_key
  end

  let(:asset) do
    asset = create(:asset, barcode: 'F02')
    sample_tube = create(:asset, uuid: test_attrs_for_asset[:sample_uuid])

    facts =
      test_attrs_for_asset.keys.map do |k|
        create(:fact, predicate: key_for_attribute(k).to_s, object: test_attrs_for_asset[k])
      end
    asset.facts << facts
    asset.facts << create(:fact, predicate: 'sample_tube', object_asset: sample_tube, literal: false)
    asset
  end

  let(:test_attrs_for_asset) do
    {
      barcode: 'F02',
      sample_uuid: 'uuid1',
      study_uuid: 'uuid2',
      pipeline: 'saphyr',
      library_type: 'lib1',
      estimate_of_gb_required: '1',
      number_of_smrt_cells: '1',
      cost_code: 'S1234',
      species: 'Homo sapiens'
    }
  end

  shared_examples_for 'a response with the required fields for Traction' do
    it 'contains the required fields for traction' do
      @body = JSON.parse(response.body)
      data = @body['data'].kind_of?(Array) ? @body['data'][0] : @body['data']
      test_attrs_for_asset.keys.each { |k| expect(data['attributes'][k.to_s]).to eq(test_attrs_for_asset[k]) }
    end
  end

  describe 'Assets' do
    describe 'GET' do
      before do
        get api_v1_asset_path(asset.uuid),
            headers: {
              'Content-Type': 'application/vnd.api+json',
              Accept: 'application/vnd.api+json'
            }
      end

      it 'returns a 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'conforms to the JSON API schema' do
        expect(response).to match_api_schema('jsonapi')
      end

      it_behaves_like 'a response with the required fields for Traction'
    end
  end

  describe 'filtering' do
    context 'when filtering by barcode' do
      let!(:sets) do
        [create(:asset, barcode: 'B01'), asset, create(:asset, barcode: 'FR03'), create(:asset, barcode: 'A1234-3')]
      end
      before do
        get api_v1_assets_path,
            params: {
              'filter[barcode]' => 'F02'
            },
            headers: {
              'Content-Type': 'application/vnd.api+json',
              Accept: 'application/vnd.api+json'
            }
      end
      it 'returns the asset' do
        data = JSON.parse(response.body).fetch('data')
        expect(data.length).to eq 1
        barcodes = data.map { |o| o['attributes']['barcode'] }
        expect(barcodes.include?('F02')).to eq(true)
      end
      it_behaves_like 'a response with the required fields for Traction'
    end
  end
end
