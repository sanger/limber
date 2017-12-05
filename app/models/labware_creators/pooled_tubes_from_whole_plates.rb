# frozen_string_literal: true

module LabwareCreators
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholePlates < Base
    extend SupportParent::TaggedPlateOnly
    include Form::CustomPage
    attr_reader :tube_transfer, :child

    self.page = 'pooled_tubes_from_whole_plates'
    self.attributes = %i[api purpose_uuid parent_uuid user_uuid barcodes]

    validate :parents_suitable

    def create_labware!
      # Create a single tube
      # TODO: This should link to multiple parents in production
      @child = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid],
        tube_attributes: [{ name: 'DN1+' }]
      ).children.first

      # Transfer EVERYTHING into it
      parents.each do |parent_plate|
        transfer_template.create!(
          user: user_uuid,
          source: parent_plate.uuid,
          destination: @child.uuid
        )
      end
    end

    # TODO: This should probably be asynchronous
    def available_plates
      plate_search = api.search.find(Settings.searches['Find plates'])
      @ongoing_plate = OngoingPlate.new(plate_purposes: [parent.plate_purpose.uuid], include_used: false, states: ['passed'])
      @search_results = plate_search.all(
        Limber::Plate,
        @ongoing_plate.search_parameters
      )
    end

    def parents
      @parents ||= api.search.find(Settings.searches['Find assets by barcode']).all(Limber::BarcodedAsset, barcode: barcodes)
    end

    def parents_suitable
      missing_barcodes = barcodes.reject(&:blank?) - parents.map {|p| p.barcode.ean13 }
      errors.add(:barcodes, "could not be found: #{missing_barcodes}") unless missing_barcodes.empty?
    end

    private

    def transfer_template
      api.transfer_template.find(
        Settings.transfer_templates['Whole plate to tube']
      )
    end
  end
end
