# frozen_string_literal: true

#
# A WellFilter is created with filter options, and in turn
# yields and validates appropriate transfers
#
# @author [grl]
#
class LabwareCreators::WellFilter
  include ActiveModel::Model

  attr_accessor :transfer_failed, :request_type_keys

  def filtered(wells)
    wells.each_with_object([]) do |well, transfers|
      next if well.empty? || (@filter_failed && well.failed?)

      transfers << [well, filter_requests(well.active_requests)]
    end
  end

  def filter_requests(requests)
    filtered_requests = requests.select { |r| @request_type_keys.blank? || @request_type_keys.include?(r.request_type.key) }
    filtered_requests.first
  end
end
