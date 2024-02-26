# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Include in API endpoints that have barcodes to add a few standard methods
  module HasWorklineIdentifier
    extend ActiveSupport::Concern

    # Finds the labware whose barcode will be printed in the label at the top_right field.
    # Uses alternative_workline_identifier from the purpose config if present, otherwise uses the stock plate.
    def workline_reference
      alternative_workline_identifier_purpose = SearchHelper.alternative_workline_reference_name(self)
      return stock_plate if alternative_workline_identifier_purpose.nil?

      ancestors.where(purpose_name: alternative_workline_identifier_purpose).last
    end

    def workline_identifier
      workline_reference&.barcode&.human
    end
  end
end
