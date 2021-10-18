# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # Pools from a plate into tubes, grouping together wells that contain the same sample
  class PooledTubesBySample < PooledTubesBase
    include SupportParent::PlateOnly

    # loop through source wells, building hash by grouping based on sample uuid
    # each hash of samples will go into one destination tube
    # set parameter on transfer request collection (if that's where it is) to consolidate identical aliquots

    # QUESTIONS:
    #
    # Should the request hash contain the submission uuid? -> Don't see why not, since we do have one.
    #
    # Should we pre-filter wells, based on whether they have been failed, or based on what request they have?
    #   -> Probably OK without - robot will be hard-coded to do a pattern of picking...
    #   -> Should check this general strategy with team, as labware creators are inconsistent.
    #
    # Does it matter we're inheriting include SupportParent::TaggedPlateOnly ?
    #
    # Should we set 'outer_request' in the request_hash? Implications of setting this, or submission, neither, or both?
    #

    # TODO:
    #
    # Get 'merge_equivalent_aliquots' functionality working
    #
    #

    def pools
      @pools ||= determine_pools
    end

    private

    #
    # Builds pools hash, based on which wells contain the same sample.
    # Uses the sample uuid as the key for the pool.
    #
    # @return [Hash] eg. { "a1aa0101-16e1-11ec-80e2-acde48001121" => ["A1", "B1"] }
    # where 'A1' and 'B1' are the coordinates of the source wells to go into that pool
    #
    def determine_pools
      pools = Hash.new { |hash, pool_name| hash[pool_name] = [] }
      parent.wells.each do |well|
        # TODO: error if well has >1 sample
        next if well.aliquots.size == 0

        sample_uuid = well.aliquots.first.sample.uuid
        pools[sample_uuid] << well.location
      end
      pools
    end

    # Don't set submission id for now, as the wrong thing is coming from PooledTubesBase
    # Set merge_equivalent_aliquots
    #
    # merge_equivalent_aliquots not working yet as expected - get following error with or without -
    # Cannot create the next piece of labware:
    # DN9000378G:B1 contains aliquots which can't be transferred due to tag clash
    def request_hash(source, target, _submission)
      {
        'source_asset' => source,
        'target_asset' => target,
        'merge_equivalent_aliquots' => true
      }
    end
  end
end
