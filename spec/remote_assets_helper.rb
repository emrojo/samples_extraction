# Provides methods for generating mock remote assets
module RemoteAssetsHelper
  def build_remote_plate(opts = {})
    purpose = double('purpose', name: 'A purpose')
    obj =
      {
        uuid: SecureRandom.uuid,
        wells: [build_remote_well('A1'), build_remote_well('A4')],
        purpose: purpose,
        type: 'plates'
      }.merge(opts)

    my_double = double('remote_asset', obj)
    allow(my_double).to receive(:attributes).and_return(obj)
    allow(my_double).to receive(:class).and_return(Sequencescape::Plate)

    my_double
  end

  def build_remote_v2_plate(opts = {})
    purpose = double('purpose', name: 'A purpose')
    obj =
      {
        uuid: SecureRandom.uuid,
        wells: [build_remote_well('A1'), build_remote_well('A4')],
        purpose: purpose,
        type: 'plates',
        sync?: true
      }.merge(opts)

    my_double = double('remote_asset', obj)
    allow(my_double).to receive(:attributes).and_return(obj)
    allow(my_double).to receive(:class).and_return(SequencescapeClientV2::Plate)

    my_double
  end

  def build_remote_well(location, opts = {})
    double(
      'well',
      {
        aliquots: [build_remote_aliquot],
        location: location,
        position: {
          'name' => location
        },
        uuid: SecureRandom.uuid,
        sync?: false
      }.merge(opts)
    )
  end

  def build_remote_tube_rack(opts = {})
    purpose = double('purpose', name: 'A purpose')
    obj =
      {
        uuid: SecureRandom.uuid,
        racked_tubes: [build_remote_racked_tube('A1'), build_remote_racked_tube('A4')],
        purpose: purpose,
        type: 'tube_racks',
        sync?: true
      }.merge(opts)

    my_double = double('remote_asset', obj)
    allow(my_double).to receive(:attributes).and_return(obj)

    my_double
  end

  def build_remote_racked_tube(coordinate, tube = nil)
    obj = { coordinate: coordinate, tube: tube || build_remote_tube }

    my_double = double('racked_tube', obj)
  end

  def build_remote_tube(opts = {})
    purpose = double('purpose', name: 'A purpose')
    obj =
      {
        uuid: SecureRandom.uuid,
        type: 'tubes',
        plate_purpose: purpose,
        aliquots: [build_remote_aliquot],
        labware_barcode: {
          'human_barcode' => 'test'
        },
        sync?: false
      }.merge(opts)
    my_double = double('remote_asset', obj)

    allow(my_double).to receive(:attributes).and_return(obj)
    allow(my_double).to receive(:class).and_return(Sequencescape::Tube)

    my_double
  end

  def build_remote_aliquot(opts = {})
    double('aliquot', { sample: build_remote_sample, study: build_study }.merge(opts))
  end

  def build_study(_opts = {})
    double('study', { name: 'STDY', uuid: SecureRandom.uuid })
  end

  def build_remote_sample(opts = {})
    attrs_for_sample =
      {
        sanger_sample_id: 'TEST-123',
        name: 'a sample name',
        sample_metadata: double('sample_metadata', { supplier_name: 'a supplier', sample_common_name: 'species' }),
        # sanger: double('sanger', { sample_id: 'TEST-123', name: 'a sample name'}),
        uuid: SecureRandom.uuid,
        # supplier: double('supplier', {sample_name: 'a supplier'}),
        updated_at: Time.now.to_s
      }.merge(opts)

    sample = double('sample', attrs_for_sample)
    allow(sample).to receive(:attributes).and_return(attrs_for_sample)
    sample
  end

  def stub_client_with_asset(double, asset)
    allow(double).to receive(:find_by_uuid).with(asset.uuid).and_return(asset)
    allow(double).to receive(:find_by_barcode) { nil }
    allow(double).to receive(:find_by_barcode).with(asset.barcode).and_return(asset)
    allow(double).to receive(:find_by_barcode).with(asset.uuid).and_return(asset)
  end
end
