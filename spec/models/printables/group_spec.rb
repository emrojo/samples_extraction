# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Printables::Group do
  describe '#classify_for_printing' do
    let!(:template1) { create(:tube_label_template) }
    let(:facts1) { [create(:fact, predicate: 'a', object: 'Tube')] }
    let(:asset1) { create(:asset, facts: facts1) }
    let(:assets) { [asset1, asset2] }
    let(:group) { create :asset_group, assets: assets }
    let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
    let!(:printer1) { create :printer, name: 'printer1' }
    let!(:printer2) { create :printer, name: 'printer2' }

    context 'when all asset are for the same printer and template' do
      let(:asset2) { create(:asset, facts: facts1) }

      it 'classifies all assets to use the right printer' do
        expect(group.classify_for_printing(config)).to eq({ ['printer1', template1] => [asset1, asset2] })
      end
    end

    context 'when each asset is for a different template and printer' do
      let!(:template2) { create(:plate_label_template) }
      let(:facts2) { [create(:fact, predicate: 'a', object: 'Plate')] }
      let(:asset2) { create(:asset, facts: facts2) }

      it 'classifies all assets to use the right printer' do
        expect(group.classify_for_printing(config)).to eq(
          { ['printer1', template1] => [asset1], ['printer2', template2] => [asset2] }
        )
      end
    end

    context 'when there is no template to print the asset' do
      let!(:template2) do
        create(:label_template, name: 'se_ean13_96plate', template_type: 'DEPRECATED_PLATE', external_id: 2)
      end
      let(:facts2) { [create(:fact, predicate: 'a', object: 'Plate')] }
      let(:asset2) { create(:asset, facts: facts2) }

      it 'raises error' do
        expect { group.classify_for_printing(config) }.to raise_error RuntimeError,
                    "Could not find any label template for type 'Plate'. Please contact LIMS support to fix the problem"
      end
    end

    context 'when there is no printer to print the asset' do
      let!(:template2) { create(:plate_label_template) }
      let(:facts2) { [create(:fact, predicate: 'a', object: 'Plate')] }
      let(:asset2) { create(:asset, facts: facts2) }
      let(:config) { { 'Tube' => 'printer1' } }

      it 'raises error' do
        expect { group.classify_for_printing(config) }.to raise_error RuntimeError,
                    'There is no defined printer for asset with type Plate'
      end
    end
  end

  context '#print' do
    let!(:template1) { create(:tube_label_template) }
    let(:facts1) { [create(:fact, predicate: 'a', object: 'Tube')] }
    let(:asset1) { create(:asset, facts: facts1, barcode: '1') }
    let(:asset2) { create(:asset, facts: facts1, barcode: '2') }
    let(:assets) { [asset1, asset2] }
    let(:group) { create :asset_group, assets: assets }
    let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
    let!(:printer1) { create :printer, name: 'printer1' }
    let!(:printer2) { create :printer, name: 'printer2' }

    before do
      allow(Rails.configuration).to receive(:printing_disabled).and_return(false)
      allow(Rails.configuration).to receive(:pmb_uri).and_return(uri)
    end

    context 'when using v1' do
      let(:uri) { 'http://localhost:10000/v1' }
      let(:post_headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
      it 'sends the right message to PMB' do
        request =
          stub_request(:post, "#{uri}/print_jobs")
            .with(
              body: {
                data: {
                  type: 'print_jobs',
                  attributes: {
                    printer_name: 'printer1',
                    label_template_id: template1.external_id,
                    labels: {
                      body: [
                        { label: { barcode: '2', barcode2d: '2', top_line: '', middle_line: nil, bottom_line: '' } },
                        { label: { barcode: '1', barcode2d: '1', top_line: '', middle_line: nil, bottom_line: '' } }
                      ]
                    }
                  }
                }
              }.to_json,
              headers: post_headers
            )
            .to_return(status: 200, body: <<~RESPONSE, headers: { 'Content-Type' => 'application/json' })
                {"data":{"type":"print_jobs","attributes":{"printer_name":"printer1","label_template_id":1,"labels":{"body":[{"label":{"barcode":"2","barcode2d":"2","top_line":"","middle_line":null,"bottom_line":""}},{"label":{"barcode":"1","barcode2d":"1","top_line":"","middle_line":null,"bottom_line":""}}]}}}}
                RESPONSE

        group.print(config)
        expect(request).to have_been_made
      end

      it 'returns a summary' do
        stub_request(:post, "#{uri}/print_jobs")
        expect(group.print(config).to_s).to eq('2 labels sent to printer1')
      end

      context 'when an asset does not have barcode' do
        let(:asset1) { create(:asset, facts: facts1, barcode: nil) }
        it 'does not print it' do
          request =
            stub_request(:post, "#{uri}/print_jobs")
              .with(
                body: {
                  data: {
                    type: 'print_jobs',
                    attributes: {
                      printer_name: 'printer1',
                      label_template_id: template1.external_id,
                      labels: {
                        body: [
                          { label: { barcode: '2', barcode2d: '2', top_line: '', middle_line: nil, bottom_line: '' } }
                        ]
                      }
                    }
                  }
                }.to_json,
                headers: post_headers
              )
              .to_return(status: 200, body: <<~RESPONSE, headers: { 'Content-Type' => 'application/vnd.api+json' })
                  {"data":{"type":"print_jobs","attributes":{"printer_name":"printer1","label_template_id":1,"labels":{"body":[{"label":{"barcode":"1","barcode2d":"1","top_line":"","middle_line":null,"bottom_line":""}}]}}}}
                  RESPONSE

          group.print(config)
          expect(request).to have_been_made
        end
      end

      it 'handles failure with a custom exception' do
        request =
          stub_request(:post, "#{uri}/print_jobs").to_return(
            status: 400,
            body: <<~RESPONSE,
                {"data":{"type":"print_jobs","attributes":{"printer_name":"printer1","label_template_id":1,"labels":{"body":[{"label":{"barcode":"2","barcode2d":"2","top_line":"","middle_line":null,"bottom_line":""}},{"label":{"barcode":"1","barcode2d":"1","top_line":"","middle_line":null,"bottom_line":""}}]}}}}
                RESPONSE
            headers: {
              'Content-Type' => 'application/json'
            }
          )

        expect { group.print(config) }.to raise_error(
          an_instance_of(PrintMyBarcodeJob::PrintingError).and(having_attributes(status_code: 400))
        )
        expect(request).to have_been_made
      end
    end

    context 'when using v2' do
      let(:uri) { 'http://localhost:10000/v2' }
      let(:post_headers) { { 'Content-Type' => 'application/json' } }

      it 'sends the right message to PMB' do
        request =
          stub_request(:post, "#{uri}/print_jobs")
            .with(
              body: {
                print_job: {
                  printer_name: 'printer1',
                  label_template_name: template1.name,
                  labels: [
                    {
                      barcode: '2',
                      barcode2d: '2',
                      top_line: '',
                      middle_line: nil,
                      bottom_line: '',
                      label_name: 'label'
                    },
                    {
                      barcode: '1',
                      barcode2d: '1',
                      top_line: '',
                      middle_line: nil,
                      bottom_line: '',
                      label_name: 'label'
                    }
                  ]
                }
              }.to_json,
              headers: post_headers
            )
            .to_return(
              status: 200,
              body: '{"message":"labels successfully printed"}',
              headers: {
                'Content-Type' => 'application/json'
              }
            )
        group.print(config)
        expect(request).to have_been_made
      end

      context 'when an asset does not have barcode' do
        let(:asset1) { create(:asset, facts: facts1, barcode: nil) }
        it 'does not print it' do
          request =
            stub_request(:post, "#{uri}/print_jobs")
              .with(
                body: {
                  print_job: {
                    printer_name: 'printer1',
                    label_template_name: template1.name,
                    labels: [
                      {
                        barcode: '2',
                        barcode2d: '2',
                        top_line: '',
                        middle_line: nil,
                        bottom_line: '',
                        label_name: 'label'
                      }
                    ]
                  }
                }.to_json,
                headers: post_headers
              )
              .to_return(
                status: 200,
                body: '{"message":"labels successfully printed"}',
                headers: {
                  'Content-Type' => 'application/json'
                }
              )

          group.print(config)
          expect(request).to have_been_made
        end
      end

      it 'handles failure with a custom exception' do
        request =
          stub_request(:post, "#{uri}/print_jobs").to_return(
            status: 400,
            body: <<~RESPONSE,
                {"data":{"type":"print_jobs","attributes":{"printer_name":"printer1","label_template_id":1,"labels":{"body":[{"label":{"barcode":"2","barcode2d":"2","top_line":"","middle_line":null,"bottom_line":""}},{"label":{"barcode":"1","barcode2d":"1","top_line":"","middle_line":null,"bottom_line":""}}]}}}}
                RESPONSE
            headers: {
              'Content-Type' => 'application/json'
            }
          )

        expect { group.print(config) }.to raise_error(
          an_instance_of(PrintMyBarcodeJob::PrintingError).and(having_attributes(status_code: 400))
        )
        expect(request).to have_been_made
      end
    end
  end
end
