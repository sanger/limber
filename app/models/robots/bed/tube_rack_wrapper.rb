# frozen_string_literal: true
module Robots::Bed
  # Tube rack info from tube metadata
  class TubeRackWrapper
    attr_accessor :barcode, :tubes
    delegate :purpose_name, :purpose, :human_barcode, :state, :uuid, to: :first_tube, allow_nil: true

    def initialize(barcode, tubes: [])
      @barcode = barcode
      @tubes = tubes
    end

    def first_tube
      @tubes.first
    end
  end
end
