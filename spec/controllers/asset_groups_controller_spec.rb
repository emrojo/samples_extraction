require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe AssetGroupsController, type: :controller do
  include RemoteAssetsHelper

  let(:asset_group) { create :asset_group }
  let(:activity_type) { create :activity_type }
  let(:activity) { create :activity, { activity_type: activity_type, asset_group: asset_group } }

  context '#upload' do
    let(:file) { fixture_file_upload('test/data/layout.csv', 'text/csv') }

    it 'creates a new uploaded file' do
      expect { post :upload, params: { id: asset_group.id, qqfilename: 'myfile.csv', qqfile: file } }.to change {
        UploadedFile.all.count
      }.by(1)
    end
    it 'adds the file to the asset group' do
      expect { post :upload, params: { id: asset_group.id, qqfilename: 'myfile.csv', qqfile: file } }.to change {
        asset_group.assets.count
      }.by(1)
    end
    it 'creates a new step to track the change in the asset group' do
      expect { post :upload, params: { id: asset_group.id, qqfilename: 'myfile.csv', qqfile: file } }.to change {
        Step.all.count
      }.by(1)
    end
  end

  context 'adding a new asset to the asset group' do
    let(:barcode) { generate :barcode }
    let(:asset) { create :asset, barcode: barcode }

    context 'when the asset is in the database' do
      context 'finding by uuid' do
        it 'add the new asset to the group' do
          expect do
            post :update,
                 params: {
                   asset_group: {
                     assets: [asset.uuid]
                   },
                   id: asset_group.id,
                   activity_id: activity.id
                 }
          end.to change { asset_group.assets.count }.by(1)
        end
      end
      context 'finding by barcode' do
        it 'add the new asset to the group' do
          expect do
            post :update,
                 params: {
                   asset_group: {
                     assets: [asset.barcode]
                   },
                   id: asset_group.id,
                   activity_id: activity.id
                 }
          end.to change { asset_group.assets.count }.by(1)
        end
      end
    end

    context 'when the asset is not in the database' do
      let(:barcode) { generate :barcode }
      let(:uuid) { SecureRandom.uuid }
      let(:remote_asset) { build_remote_tube(barcode: barcode, uuid: uuid) }

      before { stub_client_with_asset(SequencescapeClient, remote_asset) }

      context 'when it is in Sequencescape' do
        context 'finding by uuid' do
          # NOTE: We previously had an innaccurate mock making this test pass.
          # We're just pulling assets from SS based on barcode.
          xit 'retrieves the asset from Sequencescape' do
            expect do
              post :update, params: { asset_group: { assets: [uuid] }, id: asset_group.id, activity_id: activity.id }
            end.to change { asset_group.assets.count }.by(1)
          end
        end

        context 'finding by barcode' do
          it 'retrieves the asset from Sequencescape' do
            expect do
              post :update, params: { asset_group: { assets: [barcode] }, id: asset_group.id, activity_id: activity.id }
            end.to change { asset_group.assets.count }.by(1)
          end
        end
      end

      context 'when it is not in Sequencescape' do
        it 'does not retrieve anything' do
          post :update,
               params: {
                 asset_group: {
                   assets: [SecureRandom.uuid]
                 },
                 id: asset_group.id,
                 activity_id: activity.id
               }
          expect(asset_group.assets.count).to eq(0)
        end
      end

      context 'when it is a creatable barcode' do
        let(:creatable_barcode) { generate :barcode_creatable }

        it 'creates a new asset' do
          expect do
            post :update,
                 params: {
                   asset_group: {
                     assets: [creatable_barcode]
                   },
                   id: asset_group.id,
                   activity_id: activity.id
                 }
          end.to change { asset_group.assets.count }.by(1)
        end
      end
    end
  end

  describe '#print' do
    subject(:request) { post :print, params: params, format: format, session: { token: user.token } }

    let(:asset_group) { instance_double(AssetGroup, print: 'Printed') }
    let(:user) { create :user, token: 'test', tube_printer: tube_printer, plate_printer: plate_printer }
    let(:tube_printer) { create :tube_printer }
    let(:plate_printer) { create :plate_printer }

    before { allow(AssetGroup).to receive(:find).and_return(asset_group) }

    context 'when requesting json' do
      let(:format) { :json }

      context 'without any printer config' do
        let(:params) { { id: 4 } }

        it 'renders a success' do
          request
          expect(response.status).to eq(200)
          expect(response.body).to eq('{"success":true,"message":"Printed"}')
        end

        it 'users the user preferences' do
          request
          expect(asset_group).to have_received(:print).with(user.printer_config)
        end
      end

      context 'without any printer config' do
        let(:params) { { id: 4, printer_config: request_printer_config } }
        let(:request_printer_config) { { 'Plate' => 'plate printer', 'Tube' => 'Tube printer' } }

        it 'renders a success' do
          request
          expect(response.status).to eq(200)
          expect(response.body).to eq('{"success":true,"message":"Printed"}')
        end

        it 'users the request preferences' do
          request
          expect(asset_group).to have_received(:print).with(request_printer_config)
        end
      end

      context 'when there is a problem' do
        let(:params) { { id: 4 } }

        before do
          allow(asset_group).to receive(:print).and_raise(
            PrintMyBarcodeJob::PrintingError.new('The printer is on holiday', 400)
          )
        end

        it 'renders an error' do
          request
          expect(response.status).to eq(400)
          expect(response.body).to eq('{"success":false,"message":"The printer is on holiday"}')
        end
      end
    end
  end
end
