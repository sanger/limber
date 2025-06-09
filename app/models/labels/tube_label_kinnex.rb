# frozen_string_literal: true

class Labels::TubeLabelKinnex < Labels::PlateLabelBase # rubocop:todo Style/Documentation
  def attributes
    {
      top_left: date_today,
      bottom_left: labware_barcode,
      top_right: updated_identifier,
      bottom_right: labware_details,
      barcode: labware_barcode
    }
  end

  private

  def updated_identifier
    if labware.respond_to?(:source_locations)
      "#{workline_identifier}:#{labware.source_locations.first}"
    else
      workline_identifier
    end
  end

  def labware_barcode
    labware.barcode.human
  end

  def labware_details
    [labware.role, labware.purpose_name].compact.join(' ')
  end
end
