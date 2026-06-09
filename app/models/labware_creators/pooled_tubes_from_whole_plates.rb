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
      Tube.new(@child.uuid)
    end

    # TODO: This should probably be asynchronous
    # NOTE ON INCLUDES
    # `available_plates` uses `Sequencescape::Api::V2::Plate.find_all` without
    # passing an explicit `includes:` argument, so `Plate.find_all` falls back
    # to `Plate::DEFAULT_INCLUDES`. The default includes preload all information required to render the plate.
    # Without them, Limber would make additional API calls for each well, resulting in a significant increase
    # in the number of requests and slower page rendering.
    #
    # NOTE ON SORTING
    # We pass `order_by: { updated_at: :desc }` via `OngoingPlate`, and
    # `Plate.find_all` applies this to the Sequencescape query. This ensures
    # that the API returns the most recently updated plates first.
    # If no ordering is specified, the default order is by ID ascending.
    def available_plates
      @search_options = OngoingPlate.new(purposes: [parent.purpose.uuid], include_used: false, states: ['passed'],
                                         order_by: { updated_at: :desc })
      @search_results = Sequencescape::Api::V2::Plate.find_all(@search_options.search_parameters,
                                                               paginate: @search_options.pagination,
                                                               order_by: @search_options.order_by)
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
