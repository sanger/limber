# frozen_string_literal: true

module Robots::Bed
  # Plate to tube racks robot beds
  class PlateToTubeRacksBed < Robots::Bed::Base
    # TODO: Do I need this accessor?
    attr_accessor :parents

    PLATE_INCLUDES = 'purpose,wells,wells.downstream_tubes,wells.downstream_tubes.custom_metadatum_collection'

    def find_all_labware
      Sequencescape::Api::V2::Plate.find_all({ barcode: @barcodes }, includes: PLATE_INCLUDES)
    end

    def load_labware_from_parents(parents)
      return if labware.present?
      @labware = parents.flat_map(&:child_labware).select { |labware| labware.barcode == barcode }
    end

    def child_labware
      return [] if labware.nil?

      @child_labware ||= child_labware_of_plate
    end

    def child_labware_of_plate
      labware
        .wells
        .sort_by(&well_order)
        .each_with_object([]) do |well, racks|
          next if well.downstream_tubes.empty?

          well.downstream_tubes.each do |tube|
            barcode = tube.custom_metadatum_collection.metadata[:tube_rack_barcode]
            rack = racks.detect { |rack| rack.barcode == barcode } || racks.push(TubeRackWrapper.new(barcode)).last
            rack.tubes << tube
          end
        end
    end
  end
end
