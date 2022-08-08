# frozen_string_literal: true

#
# Version of WellFilter allowing partial submissions from a plate
# where the wells going forward have a specific submission id.
# i.e. not all wells need to match the well filter.
# Also adds a check on request state.
#
class LabwareCreators::WellFilterBySubmission < LabwareCreators::WellFilter
  attr_accessor :submission_id

  private

  def filter_by_submission(requests)
    requests.select do |r|
      @submission_id.to_s.include?(r.submission_id)
    end
  end

  def filter_requests(requests, well) # rubocop:todo Metrics/MethodLength
    return nil if well.requests_as_source.empty?

    filtered_requests_by_submission = filter_by_submission(requests)

    num_requests = filtered_requests_by_submission.count

    if num_requests.zero?
      # likely a partial submission, and this well is not required and has no matching request
      nil
    elsif num_requests == 1
      #  valid, one matching request found
      { 'outer_request' => filtered_requests_by_submission.first.uuid }
    else
      # too many matching requests, cannot disentangle
      errors.add(
        :base,
        "found #{num_requests} eligible requests for #{well.location}, possible overlapping submissions"
      )
    end
  end

  def well_transfers
    @well_transfers ||=
      wells.each_with_object([]) do |well, transfers|
        next if well.empty? || (@transfer_failed && well.failed?)

        filtered_requests = filter_requests(well.active_requests, well)

        # don't add wells to the transfers list if they have no filtered
        # requests, i.e. only those submitted for library prep
        transfers << [well, filtered_requests] unless filtered_requests.nil?
      end
  end
end
