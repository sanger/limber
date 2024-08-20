# frozen_string_literal: true

module LabwareCreators
  # Pools one or more plates into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholePlates < Base
    include SupportParent::TaggedPlateOnly
    include LabwareCreators::CustomPage
    attr_reader :tube_transfer, :child, :barcodes

    self.page = 'pooled_tubes_from_whole_plates'
    self.attributes += [{ barcodes: [] }]
    self.default_transfer_template_name = 'Whole plate to tube'

    validate :parents_suitable

    def create_labware!
      # Create a single tube
      # TODO: This should link to multiple parents in production
      @child =
        api
          .specific_tube_creation
          .create!(
            user: user_uuid,
            parent: parents.first.uuid,
            child_purposes: [purpose_uuid],
            tube_attributes: [{ name: "#{stock_plate_barcode}+" }]
          )
          .children
          .first

      # Transfer EVERYTHING into it
      parents.each { |parent_plate| transfer!(source_uuid: parent_plate.uuid, child_uuid: @child.uuid) }
    end

    def barcodes=(input)
      @barcodes = (input || []).map(&:strip).compact_blank
    end

    def stock_plate_barcode
      "#{parents.first.stock_plate.barcode.prefix}#{parents.first.stock_plate.barcode.number}"
    end

    # TODO: This should probably be asynchronous
    def available_plates
      @search_options = OngoingPlate.new(purposes: [parent.plate_purpose.uuid], include_used: false, states: ['passed'])
      @search_results = plate_search.all(Limber::Plate, @search_options.search_parameters)
    end

    def parents
      @parents ||=
        api.search.find(Settings.searches['Find assets by barcode']).all(Limber::BarcodedAsset, barcode: barcodes)
    end

    def parents_suitable
      missing_barcodes = barcodes - parents.map { |p| p.barcode.machine }
      return if missing_barcodes.empty?

      errors.add(:barcodes, "could not be found: #{missing_barcodes}")
    end

    def plate_search
      api.search.find(Settings.searches['Find plates'])
    end

    def number_of_parent_labwares
      # default to 4 if value not found in config
      purpose_config.fetch(:number_of_parent_labwares, 4)
    end
  end
end
