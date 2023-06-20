def remove_duplicates(_plate)
  ActiveRecord::Base.transaction do
    # wells = plate.facts.where(predicate: 'contains').map(&:object_asset)
    wells.each do |well|
      location = well.facts.where(predicate: 'location').last
      parent = well.facts.where(predicate: 'parent').last
      puts location.attributes
      location.destroy
    end
  end
end
