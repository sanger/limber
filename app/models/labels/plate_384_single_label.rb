# frozen_string_literal: true

# Prints labels for 384-well plates (single label)
# workline_identifier comes from the first stock plate of configured or last purpose
class Labels::Plate384SingleLabel < Labels::Base
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: labware.purpose_name,
      barcode: labware.barcode.human
    }
  end

  def workline_identifier
    workline_reference&.barcode&.human
  end

  # Returns stock plate with fallbacks
  def workline_reference
    plate = first_of_configured_purpose
    return plate if plate.present?

    return labware if labware.stock_plate?(purpose_names: SearchHelper.stock_plate_names)

    return labware if labware.stock_plate?(purpose_names: SearchHelper.stock_plate_names_with_flag)

    plate = first_of_last_purpose(SearchHelper.stock_plate_names)
    return plate if plate.present?

    first_of_last_purpose(SearchHelper.stock_plate_names_with_flag)
  end

  # Returns the first stock plate of the configured purpose
  def first_of_configured_purpose
    alternative_workline_identifier_purpose = SearchHelper.alternative_workline_reference_name(labware)
    return if alternative_workline_identifier_purpose.blank?

    labware.ancestors.where(purpose_name: alternative_workline_identifier_purpose).first
  end

  # Returns the first stock plate of the last purpose
  def first_of_last_purpose(purpose_names)
    return if purpose_names.blank?

    last_purpose_name = labware.ancestors.where(purpose_name: purpose_names).order(id: :asc).last&.purpose&.name

    return if last_purpose_name.blank?

    labware.ancestors.where(purpose_name: [last_purpose_name]).order(id: :asc).first
  end

  def default_printer_type
    default_printer_type_for(:plate_384_single)
  end

  def default_label_template
    default_label_template_for(:plate_384_single)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_384_single)
  end
end
