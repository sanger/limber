# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Include in receptacles which have requests directly associated with them
  # or single receptacle labware.
  module HasRequests
    # Shows the requests currently active.
    # We pre-filter cancelled requests as we tend to treat them as though they never existed
    # We then prioritise any in progress requests over those which have passed.
    # Generally, processing passed requests is a bad idea, but can be useful in
    # rare circumstances. We warn the user if they are trying to do this.
    def active_requests
      completed, in_progress = associated_requests.partition(&:completed?)
      in_progress.presence || completed
    end

    def incomplete_requests
      associated_requests.reject(&:completed?)
    end

    def multiple_requests?
      active_requests.many?
    end

    def associated_requests
      (requests_as_source + requests_in_progress).reject(&:cancelled?)
    end

    def for_multiplexing
      active_requests.any?(&:for_multiplexing)
    end

    def any_complete_requests?
      active_requests.any?(&:passed?)
    end

    def pcr_cycles
      active_requests.map(&:pcr_cycles).uniq
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

    def requests_in_progress(request_type_key: nil)
      aliquots.flat_map(&:request).compact.select do |r|
        request_type_key.nil? || r.request_type_key == request_type_key
      end
    end

    def in_progress_submission_uuids(request_type_key: nil)
      requests_in_progress(request_type_key: request_type_key).flat_map(&:submission_uuid)
    end
  end
end
