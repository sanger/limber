# frozen_string_literal: true
module Robots
  # This wrapper class is for tube racks that are not actual recorded labware.
  # The instance acts as a labware wrapper and provides access to the tubes.
  # Labware methods are delegated to the last tube on the tube rack.
  #
  class TubeRackWrapper
    attr_accessor :barcode, :parent, :tubes
    delegate :purpose_name, :purpose, :state, :uuid, to: :last_tube, allow_nil: true

    # Initializes a new instance of the class.
    #
    # @param barcode [LabwareBarcode] the barcode object of the tube rack
    # @param parent [Plate] the parent plate
    # @param tubes [Array<Tube>] the tubes on the tube rack
    #
    def initialize(barcode, parent, tubes: [])
      @barcode = barcode
      @parent = parent
      @tubes = []

      # Keep track of tube positions, tube coordinate on rack => index in
      # @tubes array, e.g. 'C1' => 0 .
      @tube_positions = {}
      tubes.each { |tube| push_tube(tube) } # Eliminate duplicate tubes by position
    end

    # Returns the last tube on the tube rack. This method is used for delegating
    # certain methods to make it behave like a labware object.
    #
    # @return [Tube] the last tube
    def last_tube
      @tubes.last
    end

    # Appends a tube to the tube rack or replaces an existing tube. If there
    # is an existing tube with the same position, the tube with the latest
    # creation date is kept.
    #
    # @param tube [Tube] the tube to be added
    # @return [Void]
    #
    def push_tube(tube)
      index = @tube_positions[tube_rack_position(tube)]
      if index.present?
        @tubes[index] = tube if tube.created_at >= @tubes[index].created_at
      else
        @tubes.push(tube)
        @tube_positions[tube_rack_position(tube)] = @tubes.length - 1
      end
    end

    # Returns the human readable barcode of the tube rack.
    #
    # @return [String] the human readable barcode
    #
    def human_barcode
      barcode.human
    end

    private

    # Returns the tube rack position of a tube from its metadata
    #
    # @param tube [Tube] the tube
    # @return [String] the tube rack position
    #
    def tube_rack_position(tube)
      tube.custom_metadatum_collection.metadata[:tube_rack_position]
    end
  end
end
