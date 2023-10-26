# frozen_string_literal: true
module Robots
  # Tube rack info from tube metadata
  class TubeRackWrapper
    attr_accessor :barcode, :parent, :tubes
    delegate :purpose_name, :purpose, :human_barcode, :state, :uuid, to: :first_tube, allow_nil: true

    def initialize(barcode, parent, tubes: [])
      @barcode = barcode
      @parent = parent
      @tubes = tubes
    end

    def first_tube
      @tubes.first
    end
  end
end
