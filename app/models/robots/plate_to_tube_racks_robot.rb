# frozen_string_literal: true

module Robots
  # This plate to tube racks robot takes one parent plate, and transfers it to
  # its child tubes that are on multiple tube racks. The tube racks handled by
  # this robot are not actual recorded labware. Their barcodes are extracted
  # from the metadata of the tubes and they are accessed using wrapper objects.
  # When robot controller calls the robot's verify or perform_transfer actions,
  # the robot will first initialize its labware store with the plate and tube
  # rack objects. The plate information comes from the Sequencescape API call,
  # however the tube rack information comes from the metadata of the downstream
  # tubes included in the same API response. Therefore, the bed verification of
  # the tube racks depend on the verification of the plate.
  #
  # The destination tube racks are distinguished by their barcodes. We assume
  # that the tubes on the same tube rack have the same labware purpose. When
  # multiple tubes of the same purpose and the same position are found, the
  # latest tube is assumed to be on the tube rack and the other tubes are
  # ignored. We also assume that there cannot be multiple tube racks with the
  # tubes of the same labware purpose on the robot at the same time.
  #
  # For bed verification, only the etched barcode of the tube racks are scanned,
  # not the individual tubes. The number of tube racks to be verified not only
  # depends on the robot's configured relationships but also whether the plate
  # has children with those purposes.
  #
  class PlateToTubeRacksRobot < Robots::SplittingRobot
    attr_writer :relationships # Hash from robot config into @relationships

    # Option for including downstream tubes and metadata in Plate API response.
    PLATE_INCLUDES = 'purpose,wells,wells.downstream_tubes,wells.downstream_tubes.custom_metadatum_collection'

    # Returns the bed class for this robot.
    #
    # @return [Class] the bed class
    def bed_class
      Robots::Bed::PlateToTubeRacksBed
    end

    # Performs the transfer between plate and tube racks. This method is called
    # by the robot controller when the user clicks the start robot button.
    #
    # @param [Hash] bed_labwares the bed_labwares hash from request parameters
    # @return [void]
    #
    def perform_transfer(bed_labwares)
      prepare_robot(bed_labwares)
      super
    end

    # Performs the bed verification of plate and tube racks. This method is
    # called by the robot controller when the user clicks the validate layout
    # button.
    #
    # @param [Hash] params request parameters
    # @return [Report]
    #
    def verify(params)
      prepare_robot(params[:bed_labwares])
      super
    end

    # Returns an array of labware from the robot's labware store for barcodes.
    # This method is called by the robot's beds when they need to find their
    # labware. The labware returned can be Plate objects or labware-like
    # wrapper objects for tube racks.
    #
    # @param [Array<String>] barcodes array of barcodes
    # @return [Array<Plate, TubeRackWrapper>]
    #
    def find_bed_labware(barcodes)
      barcodes.filter_map { |barcode| labware_store[barcode] }
    end

    # Returns an array of child labware from the robot's labware store for
    # the given Plate.
    #
    # @param [Plate] plate the parent plate
    # @return [Array<TubeRackWrapper>] array of tube rack wrapper objects
    #
    def child_labware(plate)
      labware_store.values.select { |labware| labware.respond_to?(:parent) && labware.parent.uuid == plate.uuid }
    end

    private

    # Prepares the robot before handling actions.
    #
    # @param [Hash] bed_labwares hash from request parameters
    # @return [void]
    def prepare_robot(bed_labwares)
      prepare_labware_store(bed_labwares)
      prepare_beds
    end

    # Prepares the labware store before handling robot actions. This method is
    # called before the robot's bed verification and perform transfer actions.
    #
    # @param [Hash] bed_labwares hash from request parameters
    # @return [void]
    #
    def prepare_labware_store(bed_labwares)
      return if labware_store.present?
      stripped_barcodes(bed_labwares).each do |barcode|
        plate = find_plate(barcode)
        next if plate.blank?
        add_plate_to_labware_store(plate)
        add_tube_racks_to_labware_store(plate)
      end
    end

    # Prepares the beds before handling robot actions. This method is called
    # after preparing the labware store and before assigning bed_labwares
    # request parameter to beds. It is simply modifying the config loaded
    # into the robot (beds and relationships).
    #
    # There are two reasons we need to prepare the beds. 1) If parent labware
    # cannot be found, we cannot find the child labware, hence we cannot
    # validate child beds separately. The bed verification will fail because of
    # the parent bed in this case. 2) If the parent labware can be found, but
    # the parent does not have a child labware of one of the purposes, we should
    # not validate the bed for that purpose. The bed verification will continue
    # with the expected labware.
    #
    # This method relies on the bed_labwares specified in request parameters,
    # that were already recorded by the prepare_labware_store method. We
    # override the bed configuration based on availability of labware here.
    #
    # NB. The child labware are tube-rack wrapper objects, not actual labware.
    # The information about tube-racks for are found using the metadata of the
    # downstream tubes, included in the Sequencescape API response.
    #
    # @ return [void]
    #
    def prepare_beds
      @relationships.each do |relationship|
        relationship_children = relationship.dig('options', 'children')
        labware_store_purposes = labware_store.values.map(&:purpose_name)

        bed_barcodes_to_remove =
          relationship_children.select { |barcode| labware_store_purposes.exclude?(beds[barcode].purpose) }

        delete_beds(bed_barcodes_to_remove, relationship_children)
      end
    end

    # Deletes the beds and their relationships from the robot's configuration.
    # This method is called by the prepare_beds method after finding which
    # beds should not be verified. For scRNA, this means either we need to
    # verify the parent bed first as it has a problem, or we have to remove
    # the sequencing tube-rack from the robot's config as the parent has only
    # contingency-only tube rack to be verified.
    #
    # @param [Array<String>] barcodes array of barcodes to be removed
    # @param [Array<String>] relationship_children array of child barcodes
    # @return [void]
    #
    def delete_beds(barcodes, relationship_children)
      beds.delete_if { |barcode, _bed| barcodes.include?(barcode) }
      relationship_children.delete_if { |barcode| barcodes.include?(barcode) }
    end

    # Returns an array of sanitised barcodes from the bed_labwares hash from
    # request parameters.
    #
    # @param [Hash] bed_labwares hash from request parameters
    # @return [Array<String>] array of barcodes
    #
    def stripped_barcodes(bed_labwares)
      bed_labwares.values.flatten.filter_map(&:strip).uniq
    end

    # Adds the plate to the robot's labware store.
    #
    # @param [Plate] plate the parent plate
    # @return [void]
    #
    def add_plate_to_labware_store(plate)
      labware_store[plate.barcode.human] = plate
    end

    # Adds the tube racks wrappers from plate includes to the labware store.
    #
    # @param [Plate] plate the parent plate
    # @return [void]
    #
    def add_tube_racks_to_labware_store(plate)
      find_tube_racks(plate).each { |rack| labware_store[rack.barcode.human] = rack }
    end

    # Returns the labware store. The hash is indexed by the labware barcode.
    # The values are either Plate objects or labware-like wrapper objects for
    # tube racks.
    #
    # @return [Hash<String, Labware>] the labware store
    #
    def labware_store
      @labware_store ||= {}
    end

    # Returns the Plate for the given barcode from the Sequencescape API.
    # The call includes downstream tubes and their metadata as well.
    #
    # @param [String] barcode the barcode of the plate
    # @return [Plate] the plate
    #
    def find_plate(barcode)
      Sequencescape::Api::V2::Plate.find_all({ barcode: [barcode] }, includes: PLATE_INCLUDES).first
    end

    # Returns an array of tube rack wrapper objects that from the downstream tubes
    # of the given plate.
    #
    # @param [Plate] plate the parent plate
    # @return [Array<TubeRackWrapper>] array of tube rack wrapper objects
    #
    def find_tube_racks(plate)
      plate
        .wells
        .sort_by(&well_order)
        .each_with_object([]) do |well, racks|
          next if well.downstream_tubes.blank?
          well.downstream_tubes.each do |tube|
            barcode = tube.custom_metadatum_collection.metadata[:tube_rack_barcode]
            find_or_create_tube_rack(racks, barcode, plate).push_tube(tube)
          end
        end
    end

    # Returns an existing or new tube rack wrapper object.
    #
    # @param [Array<TubeRackWrapper>] racks the tube racks found so far
    # @param [String] barcode the barcode of the tube rack
    # @param [Plate] plate the parent plate
    # @return [TubeRackWrapper] the tube rack wrapper object
    #
    def find_or_create_tube_rack(racks, barcode, plate)
      rack = racks.detect { |tube_rack| tube_rack.barcode.human == barcode }
      return rack if rack.present?
      labware_barcode = LabwareBarcode.new(human: barcode, machine: barcode)
      racks.push(TubeRackWrapper.new(labware_barcode, plate)).last
    end
  end
end
