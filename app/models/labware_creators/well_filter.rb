# frozen_string_literal: true

#
# A WellFilter is created with filter options, and in turn
# yields and validates appropriate transfers
#
# @author [grl]
#
class LabwareCreators::WellFilter
  include ActiveModel::Model

  # Indicates that the filter is unable to detect which request to use
  FilterError = Class.new(LabwareCreators::ResourceInvalid)

  attr_accessor :request_type, :library_type, :creator

  validate :well_transfers

  def filtered
    raise FilterError, self unless valid?

    well_transfers
  end

  # Returns only the filtered wells from the filtered method.
  #
  # @return [Array<Well>] the filtered wells
  def filtered_wells
    @filtered_wells ||= filtered.map(&:first)
  end

  private

  def filter_requests(requests, well)
    return extract_submission(well) if well.requests_as_source.empty?

    filtered_requests_by_rt = filter_by_request_type(requests)
    filtered_requests_by_lt = filter_by_library_type(filtered_requests_by_rt)

    if filtered_requests_by_lt.count == 1
      { outer_request: filtered_requests_by_lt.first.uuid }
    else
      errors.add(:base, "found #{filtered_requests_by_lt.count} eligible requests for #{well.location}")
    end
  end

  def extract_submission(well)
    # had a situation where request was an array rather than a single request, so added Array().first syntax
    submission_ids = well.aliquots.map { |aliquot| Array(aliquot.request).first.submission_id }.uniq
    submission_ids.one? ? { submission_id: submission_ids.first } : {}
  end

  def filter_by_request_type(requests)
    requests.select { |r| @request_type.blank? || @request_type.include?(r.request_type.key) }
  end

  def filter_by_library_type(requests)
    requests.select { |r| @library_type.blank? || @library_type.include?(r.library_type) }
  end

  def wells
    creator.labware_wells
  end

  def well_transfers
    @well_transfers ||=
      wells.each_with_object([]) do |well, transfers|
        next if well.empty? || well.failed?

        transfers << [well, filter_requests(well.active_requests, well)]
      end
  end
end
