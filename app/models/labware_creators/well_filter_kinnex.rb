# frozen_string_literal: true

# This class is used to create a well filter for Kinnex, allowing partial transfers.
class LabwareCreators::WellFilterKinnex < LabwareCreators::WellFilterAllowingPartials
  REQUEST_TYPE = %w[kinnex_prep].freeze

  # Returns an array of wells along with their filtered requests.
  # This method iterates through the wells and applies filtering logic to determine
  # which wells and their associated requests should be included in the result.
  #
  # Filtering criteria:
  # - Skips wells that are empty, not passed, or have no active requests.
  # - Uses the `filter_requests` method to filter the active requests for each well.
  # - Only includes wells in the result if they have filtered requests.
  #
  # @return [Array<[Well, Hash]>] An array of pairs, where each pair consists of:
  #   - A `Well` object.
  #   - A hash of filtered requests (or `nil` if no valid requests are found).
  def well_transfers
    @well_transfers ||=
      wells.each_with_object([]) do |well, transfers|
        next unless valid_well?(well)

        filtered_requests = filtered_requests_for_well(well)
        transfers << [well, filtered_requests] if filtered_requests
      end
  end

  def filter_requests(requests, _well)
    filter_by_request_type(requests)
  end

  def filter_by_request_type(requests)
    requests.select { |r| REQUEST_TYPE.include?(r.request_type.key) }
  end

  # Returns the wells from the parent plate that have requests of the specified type.
  # This method filters the wells of the parent plate to include only those wells
  # that have at least one request matching the types defined in `REQUEST_TYPE`.
  #
  # @return [Array<Sequencescape::Api::V2::Well>] An array of wells with matching requests.
  def well_locations
    wells.select { |well| well.requests_as_source.any? { |request| REQUEST_TYPE.include?(request.request_type.key) } }
  end

  private

  def valid_well?(well)
    !well.empty? && well.passed? && well.active_requests&.any?
  end

  def filtered_requests_for_well(well)
    requests = filter_requests(well.active_requests&.uniq, well)
    filter_by_state(requests)
  end
end
