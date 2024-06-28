# frozen_string_literal: true

# Plate label class to print off the 2 labels for Lysate plates.
# Used for the Bioscan and ANOSPP pipelines.
# First label has the standard 96-well plate label information.
# Second label has the partner plate barcode, plus a reference to the first label.
# Very specific to this particular pipeline and plate purpose.
class Labels::PlateLabe96Lysate < Labels::PlateLabelBase
  MAX_LENGTH_PARTNER_ID = 8
  PARTNER_INFO_TEXT = 'PARTNER ID LABEL'
  PARTNER_ID_SUFFIX = 'SDC'
  PARTNER_ID_MISSING = 'NO PARTNER ID FOUND'

  # Define the standard first label for the lysate plate
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # Define the second label for the lysate plate
  def additional_label_definitions
    [
      {
        top_left: date_today,
        # We repaet the lysate plate barcode on this second label so they can see the two labels go together
        bottom_left: labware.barcode.human,
        # At top right we display text to make it clear this is the partner id label
        top_right: PARTNER_INFO_TEXT,
        # This is the human readable text version of the partner id
        bottom_right: partner_id_text,
        # This is the barcode version of the partner id, with human readable text underneath
        barcode: partner_id_barcode
      }
    ]
  end

  private

  def partner_id
    @partner_id = fetch_partner_id_for_plate
  end

  def partner_id_text
    partner_id.present? ? format_partner_id : PARTNER_ID_MISSING
  end

  def partner_id_barcode
    partner_id.present? ? format_partner_id : nil
  end

  def format_partner_id
    # replace any underscores with hyphens (printer software can't handle underscores)
    formatted_partner_id = partner_id.tr('_', '-')

    # add the required suffix
    [formatted_partner_id, PARTNER_ID_SUFFIX].compact.join('-')
  end

  # Fetch the partner id from the first well that has a sample.
  # Assumption: The partner id is stored in the sample description, and all wells with
  # samples on the plate have the same partner id.
  def fetch_partner_id_for_plate
    partner_id = sample_from_first_populated_well&.sample_metadata&.sample_description

    return nil if partner_id.blank?

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
end
