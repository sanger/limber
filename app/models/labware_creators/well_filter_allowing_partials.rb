# frozen_string_literal: true

#
# Version of WellFilter allowing partial submissions from a plate.
# i.e. not all wells need to match the well filter.
# Also adds a check on request state.
#
class LabwareCreators::WellFilterAllowingPartials < LabwareCreators::WellFilter
  attr_accessor :request_state

  private

  def filter_by_state(requests)
    requests.select { |r| @request_state.blank? || @request_state.include?(r.state) }
  end

  def filter_requests(requests, well) # rubocop:todo Metrics/MethodLength
    return nil if well.requests_as_source.empty?

    filtered_requests_by_rt = filter_by_request_type(requests)
    filtered_requests_by_lt = filter_by_library_type(filtered_requests_by_rt)
    filtered_requests_by_state = filter_by_state(filtered_requests_by_lt)

    num_requests = filtered_requests_by_state.count

    if num_requests.zero?
      # likely a partial submission, and this well is not required and has no matching request
      nil
    elsif num_requests == 1
      #  valid, one matching request found
      { 'outer_request' => filtered_requests_by_state.first.uuid }
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
        # TODO: cannot find where @transfer_failed is set, and if nil allows
        # failed wells to be transferred
        next if well.empty? || (@transfer_failed && well.failed?)

        filtered_requests = filter_requests(well.active_requests, well)

        # don't add wells to the transfers list if they have no filtered requests,
        # i.e. only those submitted for library prep
        transfers << [well, filtered_requests] unless filtered_requests.nil?
      end
  end
end
