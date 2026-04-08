# frozen_string_literal: true

# This was refactored as a concern so that it could be included in the Tube model (as well as Plae),
# because one tube used a plate label and needed to use the alternative_workline_identifier config option.
module Sequencescape::Api::V2::Shared
  # Include in API endpoints that have barcodes to add a few standard methods
  module HasWorklineIdentifier
    extend ActiveSupport::Concern

    # Finds a relevant related labware in order to include its barode on the barcode label.
    # Existing use at time of writing is in the top right part of plate labels.
    # In future it could also be included on tube labels if needed.
    # Uses alternative_workline_identifier from the purpose config if present, otherwise uses the stock plate.
    # NB. the config value can be an array, in the case where there is more than one possible purpose ancestor.
    # In this case, the first one found is used.
    #
    # rubocop:disable Metrics/MethodLength
    def workline_reference
      alternative_workline_identifier_purpose = SearchHelper.alternative_workline_reference_name(self)
      return stock_plate if alternative_workline_identifier_purpose.nil?

      if alternative_workline_identifier_purpose.is_a?(Array)
        # Try each purpose name in the array in order until we find a match
        alternative_workline_identifier_purpose.each do |purpose_name|
          reference = ancestors.where(purpose_name:).last
          return reference if reference.present?
        end
        # If no matches found in the array, fall back to stock plate
        stock_plate
      else
        # Original behavior for a single purpose name
        ancestors.where(purpose_name: alternative_workline_identifier_purpose).last
      end
    end
    # rubocop:enable Metrics/MethodLength

    def workline_identifier
      workline_reference&.barcode&.human
    end
  end
end
