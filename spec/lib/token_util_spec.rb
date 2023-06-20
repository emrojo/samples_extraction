require 'rails_helper'

RSpec.describe TokenUtil do
  let(:uuid) { '00000000-0000-0000-0000-000000000001' }
  let(:wildcard) { '?variablename' }
  context '#is_uuid?' do
    it 'recognises an uuid' do
      expect(TokenUtil.is_uuid?(uuid)).to eq(true)
    end
    it 'does not recognise a quoted uuid' do
      expect(TokenUtil.is_uuid?(TokenUtil.quote(uuid))).to eq(false)
    end
    it 'does not recognise a string that contains a uuid' do
      expect(TokenUtil.is_uuid?("uuid: #{uuid} ")).to eq(false)
    end
  end
  context '#is_wildcard?' do
    it 'recognises a string that represents a wildcard' do
      expect(TokenUtil.is_wildcard?(wildcard)).to eq(true)
    end
  end
  context '#is_valid_fluidx_barcode?' do
    it 'detects a valid fluidx barcode' do
      expect(TokenUtil.is_valid_fluidx_barcode?('FR123456')).to eq(true)
    end
    it 'rejects invalid fluidx barcode' do
      expect(TokenUtil.is_valid_fluidx_barcode?('12345678')).to eq(false)
    end
  end
  context '#pad' do
    it 'pads a string with a character using a length' do
      expect(TokenUtil.pad('1234', '0', 8)).to eq('00001234')
      expect(TokenUtil.pad('1234', '0', 2)).to eq('1234')
    end
  end

  context '#pad_location' do
    it 'does not change already padded locations' do
      expect(TokenUtil.pad_location('A01')).to eq('A01')
    end
    it 'pads location not padded' do
      expect(TokenUtil.pad_location('A1')).to eq('A01')
    end
  end

  context '#unpad_location' do
    it 'does not unpad already unpadded locations' do
      expect(TokenUtil.unpad_location('A1')).to eq('A1')
    end
    it 'unpads location not unpadded' do
      expect(TokenUtil.unpad_location('A01')).to eq('A1')
    end
  end

  context '#generate_positions' do
    it 'generates a padded list of well positions' do
      expect(TokenUtil.generate_positions(('A'..'C').to_a, ('1'..'3').to_a)).to eq(
        %w[A01 B01 C01 A02 B02 C02 A03 B03 C03]
      )
    end
  end

  context '#quote' do
    it 'quotes an string' do
      expect(TokenUtil.quote('abc')).to eq("\"abc\"")
    end
  end

  context '#unquote' do
    it 'unquotes a string' do
      expect(TokenUtil.unquote("\"abc\"")).to eq('abc')
    end
  end

  context '#quote_if_uuid' do
    it 'quotes the string if is an uuid' do
      expect(TokenUtil.quote_if_uuid(uuid)).to eq("\"#{uuid}\"")
    end
    it 'does not quote the string if is not an uuid' do
      expect(TokenUtil.quote_if_uuid('text')).to eq('text')
    end
    it 'returns nil if the string is nil' do
      expect(TokenUtil.quote_if_uuid(nil)).to eq(nil)
    end
  end

  context '#kind_of_asset_id?' do
    it 'detects when an argument is a uuid' do
      expect(TokenUtil.kind_of_asset_id?(uuid)).to eq(true)
    end
    it 'detects when the argument is a wildcard' do
      expect(TokenUtil.kind_of_asset_id?(wildcard)).to eq(true)
    end
    it 'does not fail when the argument is any other value' do
      [{}, nil, Object.new, '', 'abc'].each { |val| expect(TokenUtil.kind_of_asset_id?(val)).to eq(false) }
    end
  end

  context '#machine_barcode' do
    it 'returns the barcode to_s if the barcode is already machine barcode' do
      expect(TokenUtil.machine_barcode(3_981_337_734_769)).to eq('3981337734769')
    end
    it 'returns the barcode if the barcode is already machine barcode' do
      expect(TokenUtil.machine_barcode('3981337734769')).to eq('3981337734769')
    end
    it 'returns the converted barcode if is not a machine barcode' do
      expect(TokenUtil.machine_barcode('NT1337734L')).to eq('3981337734769')
    end
  end

  context '#human_barcode' do
    it 'returns the human barcode if the barcode is already human barcode' do
      expect(TokenUtil.human_barcode('D12345678')).to eq('D12345678')
    end
    it 'returns the converted barcode from numeric machine barcode' do
      expect(TokenUtil.human_barcode(3_981_337_734_769)).to eq('NT1337734L')
    end
    it 'returns the converted barcode from string machine barcode' do
      expect(TokenUtil.human_barcode('3981337734769')).to eq('NT1337734L')
    end
  end

  context '#machine_barcode?' do
    it 'returns true if the barcode is machine barcode numeric' do
      expect(TokenUtil.machine_barcode?(12_345_678)).to eq(true)
    end
    it 'returns true if the barcode is machine barcode string' do
      expect(TokenUtil.machine_barcode?('12345678')).to eq(true)
    end
    it 'returns false any other case' do
      expect(TokenUtil.machine_barcode?('D12345678')).to eq(false)
    end
  end

  context '#human_barcode?' do
    it 'returns true if the barcode is human barcode' do
      expect(TokenUtil.human_barcode?('D12345678')).to eq(true)
    end
    it 'returns false if machine barcode numeric' do
      expect(TokenUtil.human_barcode?(12_345_678)).to eq(false)
    end
    it 'returns false if machine barcode string' do
      expect(TokenUtil.human_barcode?('12345678')).to eq(false)
    end
  end
end
