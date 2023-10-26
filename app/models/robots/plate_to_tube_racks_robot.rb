# frozen_string_literal: true

module Robots
  class PlateToTubeRacksRobot < Robots::Robot
    attr_writer :relationships

    PLATE_INCLUDES = 'purpose,wells,wells.downstream_tubes,wells.downstream_tubes.custom_metadatum_collection'

    def bed_class
      Robots::Bed::PlateToTubeRacksBed
    end

    def perform_transfer(bed_settings)
      init_labware_store(bed_settings)
      super
    end

    def verify(params)
      init_labware_store(params[:bed_labwares])
      super
    end

    def valid_relationships # rubocop:todo Metrics/AbcSize
      raise StandardError, "Relationships for #{name} are empty" if @relationships.empty?

      @relationships.each_with_object({}) do |relationship, validations|
        parent_bed = relationship.dig('options', 'parent')
        child_beds = relationship.dig('options', 'children')

        validations[parent_bed] = beds[parent_bed].child_labware.present?
        error(beds[parent_bed], 'should not be empty.') if beds[parent_bed].empty?
        error(beds[parent_bed], 'should have children.') if beds[parent_bed].child_labware.empty?

        expected_children = beds[parent_bed].child_labware
        expected_children.each_with_index do |expected_child, index|
          child_bed = child_beds[index]
          validations[child_bed] = check_labware_identity([expected_child], child_bed)
        end
      end
    end

    def find_bed_labware(barcodes)
      barcodes.filter_map { |barcode| labware_store[barcode] }
    end

    def child_labware(plate)
      labware_store.values.select { |labware| labware.respond_to?(:parent) && labware.parent.uuid == plate.uuid }
    end

    def init_labware_store(bed_labwares)
      return if labware_store.present?
      stripped_barcodes(bed_labwares).each do |barcode|
        plate = find_plate(barcode)
        next if plate.blank?
        add_plate_to_labware_store(plate)
        add_tube_racks_to_labware_store(plate)
      end
    end

    def stripped_barcodes(bed_labwares)
      bed_labwares.values.flatten.filter_map(&:strip).uniq
    end

    def add_plate_to_labware_store(plate)
      labware_store[plate.barcode.machine] = plate
    end

    def add_tube_racks_to_labware_store(plate)
      find_tube_racks(plate).each { |rack| labware_store[rack.barcode.machine] = rack }
    end

    def labware_store
      @labware_store ||= {}
    end

    def find_plate(barcode)
      Sequencescape::Api::V2::Plate.find_all({ barcode: barcode }, includes: PLATE_INCLUDES).first
    end

    def find_tube_racks(plate)
      plate
        .wells
        .sort_by(&well_order)
        .each_with_object([]) do |well, racks|
          next if well.downstream_tubes.empty?
          well.downstream_tubes.each do |tube|
            barcode = tube.custom_metadatum_collection.metadata[:tube_rack_barcode]
            rack = racks.detect { |tube_rack| tube_rack.barcode.machine == barcode }
            if rack.nil?
              labware_barcode = LabwareBarcode.new(human: barcode, machine: barcode)
              rack = racks.push(TubeRackWrapper.new(labware_barcode, plate)).last
            end
            rack.tubes << tube
          end
        end
    end
  end
end
