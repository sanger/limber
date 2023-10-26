# frozen_string_literal: true
module Robots
  # This wrapper class is for tube racks that are not actual recorded labware.
  # The instances acts as a labware wrapper and provides access to the tubes.
  # Labware methods are delegated to the first tube on the tube rack.
  #
  class TubeRackWrapper
    attr_accessor :barcode, :parent, :tubes
    delegate :purpose_name, :purpose, :human_barcode, :state, :uuid, to: :first_tube, allow_nil: true

    # Initializes a new instance of the class.
    #
    # @param [LabwareBarcode] barcode the barcode object of the tube rack
    # @param [Plate] parent the parent plate
    # @tubes [Array<Tube>] the tubes on the tube rack
    #
    def initialize(barcode, parent, tubes: [])
      @barcode = barcode
      @parent = parent
      @tubes = tubes
    end

    # Returns the first tube on the tube rack. This method used for delegating
    # certain methods to make it behave like a like a labware object.
    #
    # @return [Tube] the first tube
    def first_tube
      @tubes.first
    end
  end
end
