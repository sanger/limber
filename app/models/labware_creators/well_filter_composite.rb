# frozen_string_literal: true

# This version of WellFilter adds partial filtering conditionally.
# If the well is passed but there are still active_requests on it, it uses the WellFilterAllowingPartials
# filter_requests method.
# Otherwise it uses the base WellFilter filter_requests method.
# For e.g in scRNA core CITE branch,LRC GEM-X 5p CITE SUP XP -> LRC GEM-X 5p CITE Ligation has a closed and pending
# requests of different request_types which need to be filtered out.
# The LRC GEM-X 5p CITE SUP Input-> LRC GEM-X 5p CITE Ligation plate can have wells with only one request of
# request_type
class LabwareCreators::WellFilterComposite < LabwareCreators::WellFilterAllowingPartials
  private

  # Filters wells and their requests according to composite logic.
  #
  # For each well:
  #   - Skips wells that are empty or failed.
  #   - If the well has passed, uses the WellFilterAllowingPartials#filter_requests method
  #     to allow partial submissions and state-based filtering.
  #   - Otherwise, uses the base WellFilter#filter_requests method for strict filtering.
  #   - Only adds wells to the result if a filtered request is found (not nil).
  #
  # @return [Array<[Well, Hash]>] An array of [well, filtered_requests] pairs for wells that pass the filter.
  def well_transfers # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize
    @well_transfers ||=
      wells.each_with_object([]) do |well, transfers|
        next if well.empty? || well.failed?

        filtered_requests =
          if well.passed?
            filter_requests(well.active_requests&.uniq, well) # Calls WellFilterAllowingPartials#filter_requests
          else
            # Calls the base WellFilter#filter_requests method
            LabwareCreators::WellFilter.instance_method(:filter_requests).bind_call(
              self,
              well.active_requests&.uniq,
              well
            )
          end

        transfers << [well, filtered_requests] unless filtered_requests.nil?
      end
  end
end
