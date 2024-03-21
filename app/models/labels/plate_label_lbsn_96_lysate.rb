# frozen_string_literal: true

# Plate label class to print off the 2 labels for the Bioscan LBSN-96 Lysate plate.
# First label has the standard 96-well plate label information.
# Second label has the partner plate barcode, plus a reference to the first label.
# Very specific to this particular pipeline and plate purpose.
class Labels::PlateLabelLbsn96Lysate < Labels::PlateLabelBase
  MAX_LENGTH_PARTNER_ID = 8
  PARTNER_INFO_TEXT = 'PARTNER ID LABEL'
  PARTNER_ID_SUFFIX = 'SDC'

  # Define the standard first label for the lysate plate
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # Define the second label for the lysate plate
  def intermediate_attributes
    [
      {
        top_left: date_today,
        # We repaet the lysate plate barcode on this second label so they can see the two labels go together
        bottom_left: labware.barcode.human,
        # At top right we display text to make it clear this is the partner id label
        top_right: PARTNER_INFO_TEXT,
        # This is the human readable text version of the partner id
        bottom_right: partner_id,
        # This is the barcode version of the partner id, with human readable text underneath
        barcode: partner_id
      }
    ]
  end

  private

  def partner_id
    @partner_id ||= format_partner_id
  end

  def format_partner_id
    partner_id = fetch_partner_id_for_plate

    # replace any underscores with hyphens (printer software can't handle underscores)
    partner_id = partner_id.tr('_', '-')

    # add the required suffix
    [partner_id, PARTNER_ID_SUFFIX].compact.join('-')
  end

  # Fetch the partner id from the first well that has a sample.
  # Assumption: The partner id is stored in the sample description, and all wells woth
  # samples on the plate have the same partner id.
  def fetch_partner_id_for_plate
    partner_id = sample_from_first_populated_well&.sample_metadata&.sample_description

    raise StandardError, 'Unable to fetch partner id' if partner_id.blank?

    # trim to max length if needed
    partner_id.truncate(MAX_LENGTH_PARTNER_ID, omission: '')
  end

  # Fetch the first sample from the first well that has a sample (not a control)
  def sample_from_first_populated_well
    labware.wells_in_columns.each do |well|
      return well.aliquots.first.sample if well.aliquots.present? && well.aliquots.first.sample.control != true
    end

    raise StandardError, 'No wells with aliquots found in this labware to fetch a sample'
  end

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_a)
  end
end
