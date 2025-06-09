# frozen_string_literal: true

class Labels::TubeLabelKinnex < Labels::PlateLabelBase # rubocop:todo Style/Documentation
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: labware_details,
      barcode: labware.barcode.human
    }
  end

  private

  def workline_identifier
    labware.transfer_requests_as_target.first&.source_asset&.name
  end

  def labware_details
    [labware.role, labware.purpose_name].compact.join(' ')
  end
end
