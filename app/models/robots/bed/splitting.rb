# frozen_string_literal: true

module Robots::Bed
  # Splitting robots are specific to plates
  class Splitting < Robots::Bed::Base
    attr_accessor :parents

    def load(barcodes)
      # Ensure we always deal with an array, and any accidental duplicate scans are squashed out
      @barcodes = Array(barcodes).map(&:strip).uniq.reject(&:blank?)

      @labwares = if @barcodes.present?
                    Sequencescape::Api::V2::Plate.find_all({ barcode: @barcodes }, includes: labware_includes)
                  else
                    []
                  end
    end
  end
end
