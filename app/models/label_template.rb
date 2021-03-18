class LabelTemplate < ApplicationRecord
  validates_presence_of :name, :external_id
  validates_uniqueness_of :name, :external_id

  def self.for_type(type, barcodetype = 'ean13')
    type = {
      'Plate' => ['TubeRack', 'Plate'],
      'Tube' => ['Tube', 'SampleTube']
    }.select { |k,v| v.include?(type) }.first[0]

    templates = where(:template_type => type)

    templates_by_barcodetype = templates.select { |t| t.name.include?(barcodetype) }
    return templates if templates_by_barcodetype.empty?
    return templates_by_barcodetype
  end
end
