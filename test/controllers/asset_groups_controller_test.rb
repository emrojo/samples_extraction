# frozen_string_literal: true
require 'test_helper'
require 'minitest/mock'

class AssetGroupsControllerTest < ActionController::TestCase
  setup do
    @controller = AssetGroupsController.new
    @asset_group = FactoryGirl.create :asset_group
    @activity_type = FactoryGirl.create :activity_type
    @activity = FactoryGirl.create :activity, activity_type: @activity_type,
                                              asset_group: @asset_group
  end

  context 'adding a new barcode to the asset group' do
    context 'when the barcode is in the database' do
      setup do
        @barcode = FactoryGirl.generate :barcode
        @asset = FactoryGirl.create(:asset, barcode: @barcode)
      end

      should 'add the new asset to the group' do
        assert_difference(-> { @asset_group.assets.count }, 1) do
          post :update, asset_group: { add_barcode: @barcode },
                        id: @asset_group.id, activity_id: @activity.id
        end
      end
    end

    context 'when the barcode is not the database' do
      setup do
        @barcode = FactoryGirl.generate :barcode
      end
      context 'when it is in Sequencescape' do
        setup do
          SequencescapeClient = MiniTest::Mock.new
          SequencescapeClient.expect(:get_remote_asset, FactoryGirl.create(:asset, barcode: @barcode), [@barcode])
        end
        should 'retrieve the asset from Sequencescape' do
          assert_difference(-> { @asset_group.assets.count }, 1) do
            post :update, asset_group: { add_barcode: @barcode },
                          id: @asset_group.id, activity_id: @activity.id
          end
        end
      end

      context 'when it is a creatable barcode' do
        setup do
          @creatable_barcode = FactoryGirl.generate :barcode_creatable
        end
        should 'create a new asset' do
          assert_difference(-> { @asset_group.assets.count }, 1) do
            post :update, asset_group: {
              add_barcode: @creatable_barcode
            },
                          id: @asset_group.id, activity_id: @activity.id
          end
        end
      end
    end
  end
end
