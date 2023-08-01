module ClaimUuids # rubocop:todo Style/Documentation
  # Module for Sequencescape created to solve issue
  # process_list([preextracted, stock])
  # link_missing_wells([preextracted, stock])

  def orphan_receptacles(stock_plate_ss)
    stock_plate_ss
      .wells
      .map do |well|
        list = well.aliquots.first.sample.receptacles.select { |w| w.plate.nil? }
        puts "The plate #{stock_plate_ss.barcode} has more than one orphan for the well #{well.id}" if list.length > 1
        list
      end
      .flatten
  end

  def info_link_missing_wells(pre_extracted_plate, stock_plate)
    wells = orphan_receptacles(stock_plate)
    if pre_extracted_plate.wells.count < 96 && (pre_extracted_plate.wells.count + wells.count == 96)
      wells.each do |w|
        # rubocop:todo Layout/LineLength
        puts "You should attach barcode #{pre_extracted_plate.barcode} with id #{pre_extracted_plate.id} with well #{w.id} at #{w.map.description}"
        # rubocop:enable Layout/LineLength
      end
    else
      puts "Not found condiiton for #{stock_plate.barcode}"
    end
    puts 'No more lines'
  end

  def link_missing_wells(pre_extracted_plate, stock_plate)
    wells = orphan_receptacles(stock_plate)
    if pre_extracted_plate.wells.count < 96 && (pre_extracted_plate.wells.count + wells.count == 96)
      wells.each do |w|
        # rubocop:todo Layout/LineLength
        puts "You should attach barcode #{pre_extracted_plate.barcode} with id #{pre_extracted_plate.id} with well #{w.id} at #{w.map.description}"
        # rubocop:enable Layout/LineLength
      end
      pre_extracted_plate.wells << wells
    else
      puts "Not found condiiton for #{stock_plate.barcode}"
    end
    puts 'No more lines'
  end

  def info_about(list)
    pre_extracted_plate = Plate.find_by(barcode: list[0])
    stock_plate = Plate.find_by(barcode: list[1])
    info_link_missing_wells(pre_extracted_plate, stock_plate)
  end

  def process_list(list)
    ActiveRecord::Base.transaction do
      pre_extracted_plate = Plate.find_by(barcode: list[0])
      stock_plate = Plate.find_by(barcode: list[1])
      link_missing_wells(pre_extracted_plate, stock_plate)
    end
  end
end
