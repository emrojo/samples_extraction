# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'tempfile'
require 'csv'
require 'rest_client'

NUM_BARCODES = 96
num = 0
barcodes = []
while num < NUM_BARCODES
  number = (rand * 999_999).floor.to_s
  barcode = ['FR'].concat(Array.new((6 - number.length)) { '0' }).push(number).join
  found = Asset.find_by(barcode: barcode)
  unless found
    barcodes.push(barcode)
    num = num + 1
  end
end
puts

letters = ('A'..'H').to_a
columns = (1..12).to_a
location_for_position =
  Array.new(NUM_BARCODES) { |i| "#{letters[(i / columns.length).floor]}#{columns[i % columns.length]}" }

temp_file = Tempfile.new
CSV.open(temp_file, 'w') do |csv|
  location_for_position.each_with_index { |location, i| csv << [location, barcodes[i]] }
end

puts temp_file.read
