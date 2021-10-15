# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # ...
  class PooledTubesBySample < PooledTubesBase
    include SupportParent::PlateOnly

    # in transfer_request_attributes
    # use well_filter first
    # then ...
    # loop through source wells, building hash by grouping based on sample
    # build request hash for each of these in the hash in similar way to now,
    # except target well position is sequential rather than matching source well position
    # make sure set parameter on transfer request collection (if that's where it is) to consolidate identical aliquots

    def transfer_request_attributes(child_plate)
      sample_to_wells = pools_hash(well_filter.filtered)
      puts "*** sample_to_wells ***"
      puts sample_to_wells

      well_locations = WellHelpers.column_order

      index = 0
      request_hashes = []
      # for each sample
      sample_to_wells.each do |sample_uuid, well_filter_hashes|
        # puts "*** sample_uuid ***"
        # puts sample_uuid
        # puts "*** well_filter_hash ***"
        # puts well_filter_hash
        # puts well_filter_hash.class
        # puts well_filter_hash.size
        # puts well_filter_hash[0]

        destination_well_location = well_locations[index]
        # binding.pry
        index += 1
        # for each well containing that sample
        well_filter_hashes.each do |well_filter_hash|
          well_filter_hash.each do |well, additional_parameters|
            puts "*** well ***"
            puts well
            puts "*** additional_parameters ***"
            puts additional_parameters

            request_hashes << request_hash(well, child_plate, destination_well_location, additional_parameters)
          end
        end
      end
      request_hashes
    end

    # returns hash of samples to wells that contain that sample, in the form:
    # sample uuid => [ well filter info ]
    def pools_hash(filtered_wells)
      output = {}
      filtered_wells.each do |well, additional_parameters|
        # TODO: error if well has >1 sample
        next if well.empty?
        # binding.pry

        sample_uuid = well.aliquots.first.sample.uuid
        if output.key? sample_uuid
          output[sample_uuid] << {well => additional_parameters}
        else
          output[sample_uuid] = [{well => additional_parameters}]
        end
      end
      output
    end

    # output the transfer requests that will be sent to Sequencescape
    # to control the creation of aliquots & samples in the new labware
    def request_hash(source_well, child_plate, location, additional_parameters)
      puts "SampleConsolidatedPlate request_hash"
      # binding.pry
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect { |child_well| child_well.location == location }&.uuid,
        'merge_equivalent_aliquots' => true
      }.merge(additional_parameters)
    end
  end
end
