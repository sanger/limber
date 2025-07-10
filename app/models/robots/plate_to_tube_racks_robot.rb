# frozen_string_literal: true

module Robots
  # This plate to tube racks robot takes one parent plate, and transfers it to
  # its child tubes that are on multiple tube racks.
  # When robot controller calls the robot's verify or perform_transfer actions,
  # the robot will first initialize its labware store with the plate and tube
  # rack objects. This information comes from the Sequencescape API call on the
  # plate, where the tube racks are children of the plate.
  # Therefore, the bed verification of the tube racks depend on the verification
  # of the plate.
  #
  # For bed verification, only the etched barcode of the tube racks are scanned,
  # not the individual tubes. The number of tube racks to be verified not only
  # depends on the robot's configured relationships but also whether the plate
  # has children with those purposes. e.g. in scRNA one of the tube racks is optional.
  #
  class PlateToTubeRacksRobot < Robots::SplittingRobot
    attr_writer :relationships # Hash from robot config into @relationships

    PLATE_INCLUDES = 'purpose'

    # Returns the bed class for this robot.
    #
    # @return [Class] the bed class
    def bed_class
      Robots::Bed::PlateToTubeRacksBed
    end

    # Performs the transfer between plate and tube racks. This method is called
    # by the robot controller when the user clicks the start robot button.
    #
    # @param bed_labwares [Hash] the bed_labwares hash from request parameters (from user scanning labware into beds)
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
    # @param params [Hash] request parameters
    # @return [Report]
    #
    def verify(params)
      prepare_robot(params[:bed_labwares])
      super
    end

    # Returns an array of labware from the robot's labware store for barcodes.
    # This method is called by the robot's beds when they need to find their
    # labware. The labware returned can be Plate objects or Tube Rack objects.
    #
    # @param barcodes [Array<String>] array of barcodes
    # @return [Array<Plate, TubeRack>]
    #
    def find_bed_labware(barcodes)
      barcodes.filter_map { |barcode| labware_store[barcode] }
    end

    # Returns an array of child tube racks from the robot's labware store for
    # the given Plate.
    #
    # @param plate [Plate] the parent plate
    # @return [Array<TubeRack>] array of tube racks
    #
    def child_labware(plate)
      labware_store.values.select do |labware|
        labware.respond_to?(:parents) && labware.parents&.first&.uuid == plate.uuid
      end
    end

    private

    # Prepares the robot before handling actions.
    #
    # @param bed_labwares [Hash] the hash from request parameters
    # @return [void]
    def prepare_robot(bed_labwares)
      prepare_labware_store(bed_labwares)
      prepare_beds
    end

    # Prepares the labware store before handling robot actions. This method is
    # called before the robot's bed verification and perform transfer actions.
    # NB. This says what tube racks should be scanned, given the parent plate barcode scanned.
    # i.e. the plate barcode is scanned, and the expected tube rack children are determined.
    #
    # @param bed_labwares [Hash] the hash from request parameters
    # @return [void]
    #
    def prepare_labware_store(bed_labwares)
      return if labware_store.present?

      stripped_barcodes(bed_labwares).each do |barcode|
        plate = find_plate(barcode)

        # skip non plates
        next if plate.blank?

        # add the parent plate to the labware store
        add_plate_to_labware_store(plate)

        # determine the expected tube racks for this parent plate and add to the labware store
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
    # @ return [void]
    #
    def prepare_beds
      @relationships.each do |relationship|
        relationship_children = relationship.dig('options', 'children')
        labware_store_purposes = labware_store.values.map { |labware| labware.purpose.name }

        bed_barcodes_to_remove =
          relationship_children.select { |barcode| labware_store_purposes.exclude?(beds[barcode].purpose) }

        delete_beds(bed_barcodes_to_remove, relationship_children)
      end
    end

    # Deletes the beds and their relationships from the robot's configuration.
    # This method is called by the prepare_beds method after finding which
    # beds should not be verified. For the scRNA Core pipeline, there can be
    # a contingency rack only, or both contingency and sequencing tube racks.
    # If there is not sequencing rack required for this parent, we delete it from
    # the robot's configuration.
    #
    # @param barcodes [Array<String>] array of barcodes to be removed
    # @param relationship_children [Array<String>] array of child barcodes
    # @return [void]
    #
    def delete_beds(barcodes, relationship_children)
      beds.delete_if { |barcode, _bed| barcodes.include?(barcode) }
      relationship_children.delete_if { |barcode| barcodes.include?(barcode) }
    end

    # Returns an array of sanitised barcodes from the bed_labwares hash from
    # request parameters.
    #
    # @param bed_labwares [Hash] the hash from request parameters
    # @return [Array<String>] array of barcodes
    #
    def stripped_barcodes(bed_labwares)
      bed_labwares.values.flatten.filter_map(&:strip).uniq
    end

    # Adds the plate to the robot's labware store.
    #
    # @param plate [Plate] the parent plate
    # @return [void]
    #
    def add_plate_to_labware_store(plate)
      labware_store[plate.barcode.human] = plate
    end

    # Adds the tube racks children of the plate to the labware store.
    #
    # @param plate [Plate] the parent plate
    # @return [void]
    #
    # rubocop:disable Metrics/AbcSize
    def add_tube_racks_to_labware_store(plate)
      plate.children.each do |asset|
        # NB. children of plate are currently Assets, whereas we need TubeRack objects

        # skip when child is anything other than a tube rack
        next unless asset.type == 'tube_racks'

        # fetch tube rack from API
        tube_rack = find_tube_rack(asset.uuid)

        # cycle beds, if tube rack matches purpose and state from config, add it
        beds.each_value do |bed|
          if bed.purpose == tube_rack.purpose.name && bed.states.include?(tube_rack.state)
            labware_store[tube_rack.barcode.human] = tube_rack
          end
        end
      end
    end

    # rubocop:enable Metrics/AbcSize

    # Returns the labware store. The hash is indexed by the labware barcode.
    # The values are either Plate objects or Tube Rack objects.
    #
    # @return [Hash<String, Labware>] the labware store
    #
    def labware_store
      @labware_store ||= {}
    end

    # Returns the Plate for the given barcode from the Sequencescape API.
    # The call includes downstream tubes and their metadata as well.
    #
    # @param barcode [String] the barcode of the plate
    # @return [Plate] the plate
    #
    def find_plate(barcode)
      Sequencescape::Api::V2::Plate.find_all({ barcode: [barcode] }, includes: PLATE_INCLUDES).first
    end

    def find_tube_rack(uuid)
      Sequencescape::Api::V2::TubeRack.find_all(
        { uuid: [uuid] },
        includes: Sequencescape::Api::V2::TubeRack::DEFAULT_TUBE_RACK_INCLUDES
      ).first
    end
  end
end
