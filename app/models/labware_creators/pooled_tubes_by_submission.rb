# frozen_string_literal: true

module LabwareCreators
  # Creates a new tube per submission, and transfers all the wells matching that submission
  # into each tube.
  class PooledTubesBySubmission < PooledTubesBase
    include SupportParent::PlateReadyForPoolingOnly

    def pools
      @pools ||= parent.pools.select do |_submission_id, pool_info|
                   pool_info['for_multiplexing']
                 end.transform_values do |hash|
        hash.fetch('wells', []).select { |location| pick?(location) }
      end
    end

    def pick?(location)
      well_locations.fetch(location).passed?
    end
  end
end
