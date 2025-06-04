# frozen_string_literal: true

# This label class provides attributes for Bioscan 384-well plate labels,
# which have only a single sticker. The placement of barcode and text fields
# is similar to 96-well plate labels. Note that other 384-well plate labels
# have double stickers.
#
# The label contains a barcode image in the middle and text on the corners.
# * The barcode image in the middle contains human barcode in code128, which
#   is more compact and readable than code39. It needs empty space on both
#   sides for readabilty.
# * Top-left contains date of printing
# * Bottom-left contains human barcode of the plate
# * Top-right contains the barcode of the an ancestor stock plate. For Bioscan
#   384-well plates, we show the first LILYS barcode, or the first LYSATE
#   barcode; not last.
#
# We show an ancestor stock plate barcode; not the parent. The algorithm
# below is generic to handle the cases when ancestor plates with the same
# purpose can be stock plates or non stock plates because of alternative
# pipeline paths and/or when ancestor plates from different paths are used
# together to make a plate. We show the first of the configured alternative
# or the first of closest stock plate ancestors.
#
# Only Squix printers are used for printing 384-well plate labels. We do not
# send print requests to PMB service, instead we send them directly to SPrint
# service, which talks to Squix printers.
#
class Labels::Plate384SingleLabel < Labels::PlateLabelBase
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
    # Find the plates with configured purpose (using alternative_workline_identifier setting) and return the first.
    plate = first_of_configured_purpose
    return plate if plate.present?

    # Find the plates of the last purpose (using input_plate setting) and return the first.
    plate = first_of_last_purpose(SearchHelper.stock_plate_names)
    return plate if plate.present?

    # Find the plates of last purpose (using stock_plate setting) and return the first.
    first_of_last_purpose(SearchHelper.stock_plate_names_with_flag)
  end

  # Returns the first stock plate of the configured purpose
  def first_of_configured_purpose
    alternative_workline_identifier_purpose = SearchHelper.alternative_workline_reference_name(labware)
    return if alternative_workline_identifier_purpose.blank?

    if alternative_workline_identifier_purpose.is_a?(Array)
      find_first_matching_purpose(alternative_workline_identifier_purpose)
    else
      # Original behavior for a single purpose name
      find_reference_by_purpose_name(alternative_workline_identifier_purpose)
    end
  end

  def find_first_matching_purpose(purpose_names)
    # Try each purpose name in the array in order until we find a match
    purpose_names.each do |purpose_name|
      reference = find_reference_by_purpose_name(purpose_name)
      return reference if reference.present?
    end
    nil
  end

  def find_reference_by_purpose_name(purpose_name)
    labware.ancestors.where(purpose_name:).first
  end

  # Returns the first stock plate of the last purpose
  def first_of_last_purpose(purpose_names)
    return if purpose_names.blank?

    last_purpose_name = labware.ancestors.where(purpose_name: purpose_names).order(id: :asc).last&.purpose&.name

    return if last_purpose_name.blank?

    labware.ancestors.where(purpose_name: [last_purpose_name]).order(id: :asc).first
  end

  # There are no defaults configured for this label in the label_templates config.
  # It is configured using its section in there. The following methods are to make
  # sure that inherited defaults are not captured accidentially.

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
