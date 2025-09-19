# frozen_string_literal: true

module LabwareCreators
  # Pools one or more plates into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholePlates < Base
    include CreatableFrom::TaggedPlateOnly
    include LabwareCreators::CustomPage
    attr_reader :tube_transfer, :child, :barcodes

    self.page = 'pooled_tubes_from_whole_plates'
    self.attributes += [{ barcodes: [] }]
    self.default_transfer_template_name = 'Whole plate to tube'

    validate :parents_suitable

    def create_labware!
      # Create a single tube
      # TODO: {Y24-190} See if we can do all the transfers as part of the SpecificTubeCreation instead of separately.
      @child =
        Sequencescape::Api::V2::SpecificTubeCreation
          .create!(
            child_purpose_uuids: [purpose_uuid],
            parent_uuids: [parents.first.uuid],
            # NB. name is overridden in the after_create method in Transfer::FromPlateToTube
            # in Sequencescape, to use the stock plate barcode and well range, so not set here
            tube_attributes: [{}],
            user_uuid: user_uuid
          )
          .children
          .first

      # Transfer EVERYTHING into it
      parents.each { |parent_plate| transfer!(source_uuid: parent_plate.uuid, destination_uuid: @child.uuid) }
    end

    def barcodes=(input)
      @barcodes = (input || []).map(&:strip).compact_blank
    end

    def redirection_target
      Tube.new(nil, @child.uuid)
    end

    # TODO: This should probably be asynchronous
    def available_plates
      @search_options = OngoingPlate.new(purposes: [parent.purpose.uuid], include_used: false, states: ['passed'])
      @search_results = Sequencescape::Api::V2::Plate.find_all(@search_options.search_parameters)
    end

    def parents
      @parents ||= Sequencescape::Api::V2::Labware.find(barcode: barcodes)
    end

    def parents_suitable
      missing_barcodes = barcodes - parents.map { |p| p.barcode.machine }
      return if missing_barcodes.empty?

      errors.add(:barcodes, "could not be found: #{missing_barcodes}")
    end

    def number_of_parent_labwares
      # default to 4 if value not found in config
      purpose_config.fetch(:number_of_parent_labwares, 4)
    end
  end
end
