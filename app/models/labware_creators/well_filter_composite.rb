# frozen_string_literal: true

#
class LabwareCreators::WellFilterComposite < LabwareCreators::WellFilterAllowingPartials
  private

  def well_transfers # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize
    @well_transfers ||=
      wells.each_with_object([]) do |well, transfers|
        next if well.empty? || well.failed?

        filtered_requests =
          if well.passed?
            filter_requests(well.active_requests&.uniq, well) # Calls WellFilterAllowingPartials#filter_requests
          else
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
