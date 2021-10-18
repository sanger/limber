# frozen_string_literal: true

module LabwareCreators
  # Creates a new tube per submission, and transfers all the wells matching that submission
  # into each tube.
  class PooledTubesBySubmission < PooledTubesBase
    include SupportParent::PlateReadyForPoolingOnly

    def pools
      @pools ||= determine_pools
    end

    private

    # This code could be compressed, but keep it open for readability
    def determine_pools
      # pools are already defined on the parent plate, since they are set at the point of submission
      # filter for just those that are marked for multiplexing
      pools_for_multiplexing = parent.pools.select do |_submission_id, pool_info|
        pool_info['for_multiplexing']
      end

      # filter for just those where the source wells for the pool have't been failed
      pools_for_multiplexing.transform_values { |pool_info| all_wells_in_pool_passed?(pool_info) }
    end

    def all_wells_in_pool_passed?(pool_info)
      pool_info.fetch('wells', []).select { |location| pick?(location) }
    end

    def pick?(location)
      well_locations.fetch(location).passed?
    end
  end
end
