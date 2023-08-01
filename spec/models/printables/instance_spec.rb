# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Printables::Instance do
  context '#print' do
    let!(:template1) { create(:tube_label_template) }
    let(:props1) { [create(:fact, predicate: 'a', object: 'Tube')] }
    let(:asset1) { create(:asset, facts: props1, barcode: '1') }
    let(:config) { { 'Tube' => 'printer1', 'Plate' => 'printer2' } }
    let!(:printer1) { create :printer, name: 'printer1' }
    let!(:printer2) { create :printer, name: 'printer2' }

    before do
      allow(Rails.configuration).to receive(:printing_disabled).and_return(false)
      allow(Rails.configuration).to receive(:pmb_uri).and_return(uri)
    end

    context 'v1 API' do
      let(:uri) { 'http://localhost:10000/v1' }

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
                        { label: { barcode: '1', barcode2d: '1', top_line: '', middle_line: nil, bottom_line: '' } }
                      ]
                    }
                  }
                }
              }.to_json
            )
            .to_return(
              status: 200,
              body: '{ "message": "labels successfully printed" }',
              headers: {
                'Content-Type' => 'application/vnd.api+json'
              }
            )
        asset1.print(config)
        expect(request).to have_been_made
      end

      context 'when an asset does not have barcode' do
        let(:asset1) { create(:asset, facts: props1, barcode: nil) }
        it 'does not print it' do
          asset1.print(config)
          expect(a_request(:post, "#{uri}/print_jobs")).not_to have_been_made
        end
      end
    end

    context 'v2 API' do
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
        asset1.print(config)
        expect(request).to have_been_made
      end

      context 'when an asset does not have barcode' do
        let(:asset1) { create(:asset, facts: props1, barcode: nil) }
        it 'does not print it' do
          asset1.print(config)
          expect(a_request(:post, "#{uri}/print_jobs")).not_to have_been_made
        end
      end
    end
  end
end
