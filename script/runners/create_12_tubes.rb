# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

return unless ARGV.any? { |s| s.match('.json') }

TOTAL_NUMBER = 12

tubes = Array.new(TOTAL_NUMBER) { |i| "?p#{i}" }
samples = Array.new(TOTAL_NUMBER) { |i| "?q#{i}" }
sanger_sample_id = Array.new(TOTAL_NUMBER) { |i| "SAMPLE#{i}" }
study_name = 'STDY1'

f1 = tubes.each_with_index.map { |t, _i| [t, 'a', 'SampleTube'] }
f2 = tubes.each_with_index.map { |t, _i| [t, 'is', 'NotStarted'] }
f3 = tubes.each_with_index.map { |t, i| [t, 'sample_tube', samples[i]] }
f4 = tubes.each_with_index.map { |t, i| [t, 'sanger_sample_id', sanger_sample_id[i]] }
f5 = tubes.each_with_index.map { |t, _i| [t, 'study_name', study_name] }
f6 = tubes.each_with_index.map { |t, _i| [t, 'transferVolume', 20] }
f7 = tubes.each_with_index.map { |t, _i| [t, 'volume', 100] }

all_assets = tubes + samples
obj = {
  create_assets: all_assets,
  add_facts: [f1, f2, f3, f4, f5, f6, f7].reduce([]) { |memo, facts| memo.concat(facts) },
  add_assets: [tubes]
}.to_json

puts obj
