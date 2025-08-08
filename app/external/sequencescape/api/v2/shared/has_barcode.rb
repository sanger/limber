# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Include in API endpoints that have barcodes to add a few standard methods
  module HasBarcode
    extend ActiveSupport::Concern

    included do
      property :labware_barcode, type: :barcode

      alias_method :barcode, :labware_barcode
    end

    def human_barcode
      labware_barcode.human
    end
  end
end
