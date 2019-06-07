require 'rails_helper'
RSpec.describe AssetsController, type: :controller do
  before do
    session[:token] = 'mytoken'
    create :printer, printer_type: 'Tube', default_printer: true, name: 'Pim'
    create :printer, printer_type: 'Plate', default_printer: true, name: 'Pum'
    @user = create :user, token: session[:token], username: 'test'
  end

  shared_examples_for 'a search action from a controller' do
    it 'renders a search' do
      send(method, action_name, params: { q: 'S1234'}, xhr: true)
      assert_response :success
      expect(response).to render_template :search
    end
    it 'searches by barcode' do
      asset = create :asset, barcode: 'S1234'
      search = Asset.where(barcode: 'S1234')
      send(method, action_name, params: { p0: 'barcode', o0: 'S1234'}, xhr: true)
      expect(assigns(:assets)).to eq(search)
    end
    it 'searches by properties' do
      asset = create :asset, barcode: 'S1234'
      asset.facts << create(:fact, predicate: 'a', object: 'Tube')
      search = Asset.joins(:facts).where(facts: { predicate: 'a', object: 'Tube'}).first
      send(method, action_name, params: { p0: 'a', o0: 'Tube'}, xhr: true)
      expect(assigns(:assets)).to eq([search])
    end
  end
  context '#search' do
    let(:method) {:get}
    let(:action_name) { :search }
    it_behaves_like 'a search action from a controller'
  end
  context '#print_search' do
    let(:method) {:post}
    let(:action_name) { :print_search }
    it_behaves_like 'a search action from a controller'

    it 'prints the barcodes of the assets from the query' do
      allow(Printables::Group).to receive(:print_assets)

      asset = create :asset, barcode: 'S1234'
      search = Asset.where(barcode: 'S1234')
      post :print_search, params: { p0: 'barcode', o0: 'S1234'}, xhr: true
      expect(assigns(:assets)).to eq(search)

      expect(Printables::Group).to have_received(:print_assets).with(search, {"Plate"=>'Pum', "Tube"=>'Pim'}, 'test')
    end
  end
end