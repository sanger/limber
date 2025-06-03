# frozen_string_literal: true

# This class is used to create a well filter for Kinnex, allowing partial transfers.
class LabwareCreators::WellFilterKinnex < LabwareCreators::WellFilterAllowingPartials
  # Returns an array of wells along with their filtered requests.
  # This method iterates through the wells and applies filtering logic to determine
  # which wells and their associated requests should be included in the result.
  #
  # Filtering criteria:
  # - Skips wells that are empty, not passed, or have no active requests.
  # - Uses the `filter_requests` method to filter the active requests for each well.
  # - Only includes wells in the result if they have filtered requests.
  #
  # @return [[Well, [Request]] An array of pairs, where each pair consists of:
  #   - A `Well` object.
  #   - A hash of filtered requests (or `nil` if no valid requests are found).
  def well_transfers
    @well_transfers ||=
      wells
        .select { |well| valid_well?(well) }
        .each_with_object([]) do |well, transfers|
          filtered_requests = filtered_requests_for_well(well)
          transfers << [well, filtered_requests] if filtered_requests
        end
  end

  private

  def valid_well?(well)
    !well.empty? && well.active_requests&.any?
  end

  def filtered_requests_for_well(well)
    filter_by_state(filter_by_request_type(well.active_requests&.uniq))
  end
end
