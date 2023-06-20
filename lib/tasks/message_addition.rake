# frozen_string_literal: true

namespace :message_addition do
  desc 'Add uuids to any assets missing them'
  task back_populate_uuids: :environment do
    # Control how many samples are processed in a batch. Main limitation here
    # is the limits on the query to the Sequencescape API.
    block_size = 100

    puts 'Finding samples needing uuids...'
    asset_sample_ids =
      Fact
        .with_predicate('sanger_sample_id')
        .joins("LEFT OUTER JOIN facts AS uuid ON uuid.predicate = 'sample_uuid' AND uuid.asset_id = facts.asset_id")
        .where(uuid: { object: nil })
        .pluck('facts.asset_id', 'facts.object')
    puts "#{asset_sample_ids.length} to migrate"
    asset_sample_ids.each_slice(block_size) do |slice|
      puts '=' * 80
      puts "Processing #{slice.first.inspect} to #{slice.last.inspect}"
      puts 'Looking up uuids'
      sanger_sample_ids = slice.map(&:last)
      uuid_hash =
        SequencescapeClientV2::Sample
          .where(sanger_sample_id: sanger_sample_ids)
          .select(:sanger_sample_id, :uuid)
          .all
          .each_with_object({}) { |sample, store| store[sample.sanger_sample_id] = sample.uuid }
      puts 'Building facts'
      fact_attributes =
        slice.filter_map do |asset_id, sanger_sample_id|
          next if uuid_hash[sanger_sample_id].nil?

          { asset_id: asset_id, predicate: 'sample_uuid', object: uuid_hash[sanger_sample_id] }
        end
      puts 'Creating facts'
      Fact.create!(fact_attributes)
      puts 'Done!'
    end
  end

  desc 'Broadcast historic activities'
  task back_populate_activities: %i[environment back_populate_uuids] do
    # Control how many samples are processed in a batch. Main limitation here
    # is the limits on the query to the Sequencescape API.
    Activity.finished.find_each do |activity|
      puts "Sending activity #{activity.id}"
      if activity.steps.empty?
        puts 'Skipping... no steps'
        next
      end
      activity.send(:send_message)
    end
  end
end
