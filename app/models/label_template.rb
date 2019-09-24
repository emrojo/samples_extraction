class LabelTemplate < ActiveRecord::Base
  #validates_presence_of :name, :external_id
  #validates_uniqueness_of :name, :external_id

  def self.external_id_for_type(type, barcodetype = 'ean13')
    for_type(type, barcode_type).map do |template|
      PMB::LabelTemplate.where(name: template.name).first
    end.compact.map(&:id).first
  end

  def pmb_template_for_asset(asset)
  end

  def self.for_type(type, barcodetype = 'ean13')
    type = {
      'Plate' => ['TubeRack', 'Plate'],
      'Tube' => ['Tube', 'SampleTube']
    }.select{|k,v| v.include?(type)}.first[0]

    templates = where(:template_type => type)

    templates_by_barcodetype = templates.select{|t| t.name.include?(barcodetype)}

    return templates if templates_by_barcodetype.empty?
    return templates_by_barcodetype
  end
end
