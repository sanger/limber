# frozen_string_literal: true

#
# Version of WellFilter allowing partial submissions from a plate.
#
class LabwareCreators::WellFilterAllowingPartials < LabwareCreators::WellFilter
  private

  def filter_requests(requests, well)
    return extract_submission(well) if well.requests_as_source.empty?

    filtered_requests = filter_by_request_type(requests)
    filtered_requests_by_library_type = filter_requests_by_library_type(filtered_requests)

    num_requests = filtered_requests_by_library_type.count

    if num_requests.zero?
      # likely a partial submission, and this well is not required and has no matching request
      nil
    elsif num_requests == 1
      #  valid, one matching request found
      { 'outer_request' => filtered_requests_by_library_type.first.uuid }
    else
      # too many matching requests, cannot disentangle
      errors.add(:base, "found #{num_requests} eligible requests for #{well.location}, possible overlapping submissions")
    end
  end

  def well_transfers
    @well_transfers ||= wells.each_with_object([]) do |well, transfers|
      next if well.empty? || (@transfer_failed && well.failed?)

      filtered_requests = filter_requests(well.active_requests, well)

      # don't add wells to the transfers list if they have no filtered requests
      transfers << [well, filtered_requests] unless filtered_requests.nil?
    end
  end
end
