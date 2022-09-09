# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Provides a number of methods for dealing with requests
  # Requires the included class implement:
  # #aliquots => Array<Sequencescape::Api::V2::Aliquot>
  # #requests_as_source => Array<Sequencescape::Api::V2::Request>
  # @todo This should probably be converted to a proxy class
  module HasRequests
    # Shows the requests currently active.
    # We pre-filter cancelled requests as we tend to treat them as though they never existed
    # We then prioritise any in progress requests over those which have passed.
    # Generally, processing passed requests is a bad idea, but can be useful in
    # rare circumstances. We warn the user if they are trying to do this.
    # @note Plate has its own active_requests method which overrides this one and
    #       works out active requests on a per-well basis.
    def active_requests
      incomplete_requests.presence || complete_requests
    end

    def incomplete_requests
      @incomplete_requests || partition_requests.last
    end

    # Based on active requests

    def multiple_requests?
      active_requests.many?
    end

    def for_multiplexing
      active_requests.any?(&:for_multiplexing)
    end

    def any_complete_requests?
      active_requests.any?(&:passed?)
    end

    def pcr_cycles
      active_requests.filter_map(&:pcr_cycles).uniq
    end

    def role
      active_requests.detect(&:role)&.role
    end

    def priority
      active_requests.map(&:priority).max || 0
    end

    def submission_ids
      active_requests.map(&:submission_id).uniq
    end

    def pool_id
      submission_ids.first
    end

    # Finding 'in_progress' requests

    def requests_in_progress(request_type_key: nil)
      aliquots
        .flat_map(&:request)
        .compact
        .select { |r| request_type_key.nil? || r.request_type_key == request_type_key }
    end

    # Based on in_progress requests

    def in_progress_submission_uuids(request_type_key: nil)
      requests_in_progress(request_type_key: request_type_key).flat_map(&:submission_uuid).uniq
    end

    def all_requests
      requests_as_source + requests_in_progress
    end

    private

    def associated_requests
      @associated_requests ||= all_requests.reject(&:cancelled?)
    end

    def complete_requests
      @complete_requests || partition_requests.first
    end

    def partition_requests
      @complete_requests, @incomplete_requests = associated_requests.partition(&:completed?)
    end
  end
end
