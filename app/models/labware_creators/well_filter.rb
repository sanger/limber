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

  attr_accessor :transfer_failed, :request_type_keys, :creator

  validate :well_transfers

  def filtered
    raise FilterError, self unless valid?

    well_transfers
  end

  def filter_requests(requests, well)
    filtered_requests = requests.select { |r| @request_type_keys.blank? || @request_type_keys.include?(r.request_type.key) }
    if filtered_requests.count == 1
      filtered_requests.first
    else
      errors.add(:base, "found #{filtered_requests.count} eligible requests for #{well.location}")
    end
  end

  def wells
    creator.labware_wells
  end

  private

  def well_transfers
    @well_transfers ||= wells.each_with_object([]) do |well, transfers|
      next if well.empty? || (@transfer_failed && well.failed?)

      transfers << [well, filter_requests(well.active_requests, well)]
    end
  end
end
