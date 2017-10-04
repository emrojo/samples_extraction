require 'rails_helper'
require 'remote_assets_helper'

RSpec.describe 'Asset::Import' do
	include RemoteAssetsHelper

  context '#find_or_import_asset_with_barcode' do
  	context 'when importing an asset that does not exist' do
  		setup do
  			allow(SequencescapeClient).to receive(:get_remote_asset).and_return(nil)
  		end
  		it 'should return nil' do
  			expect(Asset.find_or_import_asset_with_barcode('NOT_FOUND')).to eq(nil)
  		end
      it 'should not create a new asset' do
        expect(Asset.all.count).to eq(0)
        Asset.find_or_import_asset_with_barcode('NOT_FOUND')
        expect(Asset.all.count).to eq(0)
      end
  	end
  	context 'when importing a local asset' do
  		setup do
  			@barcode_plate = "1"
  			@asset = Asset.create!(barcode: @barcode_plate)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(@barcode_plate)).to eq(@asset)
  		end
  		it 'should return the local asset when looking by its barcode' do
  			expect(Asset.find_or_import_asset_with_barcode(@asset.uuid)).to eq(@asset)
  		end
  	end
  	context 'when importing a remote asset' do
			setup do
				SequencescapeClient = double('sequencescape_client')

        @remote_plate_asset = build_remote_plate(barcode: '2')
        @barcode_plate = @remote_plate_asset.barcode 
        stub_client_with_asset(SequencescapeClient, @remote_plate_asset)
			end

      context 'when the asset is a tube' do
        setup do
          @remote_tube_asset = build_remote_tube(barcode: '1')
          stub_client_with_asset(SequencescapeClient, @remote_tube_asset)
        end
        it 'should try to obtain a tube' do
          @asset = Asset.find_or_import_asset_with_barcode(@remote_tube_asset.barcode)
          expect(SequencescapeClient).to have_received(:find_by_uuid).with(@remote_tube_asset.uuid, :tube)
        end
      end

      context 'when the asset is a plate' do
        setup do
          @remote_plate_asset = build_remote_plate(barcode: '2')
          stub_client_with_asset(SequencescapeClient, @remote_plate_asset)
        end
        it 'should try to obtain a plate' do
          @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset.barcode)
          expect(SequencescapeClient).to have_received(:find_by_uuid).with(@remote_plate_asset.uuid, :plate)
        end

        context 'when the supplier sample name has not been provided to some samples' do
          setup do
            wells = [
              build_remote_well('A1', aliquots: [build_remote_aliquot(sample: build_remote_sample(supplier: nil))]),
              build_remote_well('B1', aliquots: [build_remote_aliquot(sample: build_remote_sample(supplier: double('supplier', sample_name: nil)))]),
              build_remote_well('C1', aliquots: [build_remote_aliquot(sample: build_remote_sample(supplier: double('supplier', sample_name: 'a supplier name')))]),
              build_remote_well('D1', aliquots: [build_remote_aliquot(sample: build_remote_sample(supplier: double('supplier', sample_name: 'a supplier name')))])
            ]
            @remote_plate_asset_without_supplier = build_remote_plate(barcode: '5', wells: wells)
            stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_supplier)            
          end
          it 'adds the information of the samples to the wells that have a supplier name defined' do
            @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_supplier.barcode)
            
            assets_with_samples = @asset.facts.with_predicate('contains').map(&:object_asset).compact.select do |asset|
              asset.facts.with_predicate('sanger_sample_id').count > 0
            end
            expect(assets_with_samples.count).to eq(2)
            expect(assets_with_samples.map do |w| 
              w.facts.with_predicate('location').map(&:object)
            end.flatten).to eq(['C1','D1'])
          end
        end

        context 'when the plate does not have aliquots in its wells' do
          setup do
            wells = ['A1','B1'].map {|l| build_remote_well(l, aliquots: []) }
            @remote_plate_asset_without_aliquots = build_remote_plate(barcode: '3', wells: wells)
            stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_aliquots)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_aliquots.barcode)
            wells = @asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(@remote_plate_asset_without_aliquots.wells).all?{|w,w2| w.uuid == w2.uuid}).to eq(true)
          end
        end
        context 'when the plate does not have samples in its wells' do
          setup do
            wells = ['A1','B1'].map {|l| build_remote_well(l, aliquots: [build_remote_aliquot(sample: nil)]) }
            @remote_plate_asset_without_samples = build_remote_plate(barcode: '4', wells: wells)
            stub_client_with_asset(SequencescapeClient, @remote_plate_asset_without_samples)
          end
          it 'creates the wells with the same uuid as in the remote asset' do
            @asset = Asset.find_or_import_asset_with_barcode(@remote_plate_asset_without_samples.barcode)
            wells = @asset.facts.with_predicate('contains').map(&:object_asset)
            expect(wells.zip(@remote_plate_asset_without_samples.wells).all?{|w,w2| w.uuid == w2.uuid}).to eq(true)
          end
        end
      end

			it 'should create the corresponding facts from the json' do
				@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
				@asset.facts.reload
				expect(@asset.facts.count).to eq(7)
			end

		  context 'for the first time' do
		  	it 'should create the local asset' do
		  		expect(Asset.count).to eq(0)
		  		Asset.find_or_import_asset_with_barcode(@barcode_plate)
		  		expect(Asset.count>0).to eq(true)
		  	end
		  end
		  context 'when is already imported' do
        context 'when the remote source is not present anymore' do
          setup do
            @asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
            allow(SequencescapeClient).to receive(:find_by_uuid).and_return(nil)
          end
          it 'should raise an exception' do
            expect{Asset.find_or_import_asset_with_barcode(@barcode_plate)}.to raise_exception Asset::Import::RefreshSourceNotFoundAnymore
          end
        end
        context 'when the remote source is present' do
  		  	setup do
  		  		@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  	end
  		  	it 'should not create a new local asset' do
  		  		count = Asset.count
  					Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  		expect(Asset.count).to eq(count)
  		  	end

  		  	context 'when the local copy is up to date' do
  		  		it 'should not destroy any remote facts' do
  		  			remote_facts = @asset.facts.from_remote_asset
  		  			remote_facts.each(&:reload)
  		  			Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  			expect{remote_facts.each(&:reload)}.not_to raise_exception ActiveRecord::RecordNotFound
  		  		end
  		  	end

  		  	context 'when the local copy is out of date' do
  		  		setup do
  		  			@asset.update_attributes(remote_digest: 'RANDOM')
  		  		end
  		  		it 'should destroy any remote facts' do
  		  			remote_facts = @asset.facts.from_remote_asset
  		  			remote_facts.each(&:reload)
  		  			Asset.find_or_import_asset_with_barcode(@barcode_plate)	
  		  			expect{remote_facts.each(&:reload)}.to raise_exception ActiveRecord::RecordNotFound
  		  		end
            
            it 'should destroy any contains dependant remote facts' do
              remote_facts = @asset.facts.with_predicate('contains').map(&:object_asset).map{|w| w.facts.from_remote_asset}.flatten
              remote_facts.each(&:reload)
              Asset.find_or_import_asset_with_barcode(@barcode_plate) 
              expect{remote_facts.each(&:reload)}.to raise_exception ActiveRecord::RecordNotFound            
            end

  		  		it 'should re-create all the remote facts' do
  		  			count = @asset.facts.from_remote_asset.count
  		  			@asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
  		  			@asset.facts.reload
  		  			expect(@asset.facts.from_remote_asset.count).to eq(count)
  		  		end

            it 'should re-create the dependant remote facts' do
              dependant_facts = @asset.facts.with_predicate('contains').map(&:object_asset).map do |w| 
                w.facts.from_remote_asset 
              end.flatten.compact
              count = dependant_facts.count
              @asset = Asset.find_or_import_asset_with_barcode(@barcode_plate)
              @asset.facts.reload
              dependant_facts2 = @asset.facts.with_predicate('contains').map(&:object_asset).map do |w| 
                w.facts.from_remote_asset 
              end.flatten.compact
              count2 = dependant_facts2.count
              expect(count).to eq(count2)
            end
  		  	end
        end
		  end
  	end
  end
end