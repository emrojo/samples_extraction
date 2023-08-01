require 'rails_helper'

RSpec.describe ActivitiesController, type: :controller do
  before do
    session[:token] = 'mytoken'
    create :printer, printer_type: 'Tube', default_printer: true, name: 'Pim'
    create :printer, printer_type: 'Plate', default_printer: true, name: 'Pum'
    @user = create :user, token: session[:token], username: 'test'
  end

  setup do
    @activity_type = FactoryBot.create :activity_type
    @kit_type = FactoryBot.create :kit_type, activity_type: @activity_type
    @kit = FactoryBot.create :kit, { kit_type: @kit_type }
    @instrument = FactoryBot.create :instrument
  end

  context 'when updating an activity' do
    before { @activity = @kit.kit_type.activity_type.create_activity({ kit: @kit, instrument: @instrument }) }
    it 'can finish the activity' do
      post :update, params: { id: @activity.id, activity: { state: 'finish' } }
      @activity.reload
      expect(@activity.state).to eq('finish')
    end
  end
  context 'when scanning a new kit' do
    context 'when the kit does not exist' do
      let(:subject) do
        post :create, params: { activity: { kit_barcode: '11850', instrument_barcode: @instrument.barcode } }
      end
      it 'fails creating the activity' do
        count = @kit.kit_type.activity_type.activities.count
        subject
        @kit.kit_type.activity_type.activities.reload
        assert_equal @kit.kit_type.activity_type.activities.count, count
        assert_equal @activity_type.activities.count, count
      end
      it 'redirects to the use instrument view' do
        expect(subject).to redirect_to(use_instrument_path(@instrument))
      end
    end
    context 'when the kit exists' do
      context 'when the instrument does not support the activity type' do
        let(:subject) do
          post :create, params: { activity: { kit_barcode: @kit.barcode, instrument_barcode: @instrument.barcode } }
        end
        it 'fails creating the activity' do
          count = @kit.kit_type.activity_type.activities.count
          subject
          @kit.kit_type.activity_type.activities.reload
          assert_equal @kit.kit_type.activity_type.activities.count, count
          assert_equal @activity_type.activities.count, count
        end
        it 'redirects to the use instrument view' do
          expect(subject).to redirect_to(use_instrument_path(@instrument))
        end
      end
      context 'when the instrument supports the activity type selected by the kit' do
        before { @instrument.activity_types << @activity_type }
        it 'creates a new activity' do
          count = @kit.kit_type.activity_type.activities.count
          post :create, params: { activity: { kit_barcode: @kit.barcode, instrument_barcode: @instrument.barcode } }
          @kit.kit_type.activity_type.activities.reload
          assert_equal @kit.kit_type.activity_type.activities.count, count + 1
          assert_equal @activity_type.activities.count, count + 1
        end
      end
    end
  end
end
