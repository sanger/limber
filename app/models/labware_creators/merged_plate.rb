# frozen_string_literal: true

module LabwareCreators
  # Merges plates together into a single child plate, and de-duplicates aliquots if they are identical.
  class MergedPlate < StampedPlate
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_reader :child
    attr_accessor :barcodes

    self.attributes += [{ barcodes: [] }]

    self.page = 'merged_plate'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    def labware_wells
      source_plates.flat_map(&:wells)
    end

    private

    def create_plate_from_parent!
      api.pooled_plate_creation.create!(
        child_purpose: purpose_uuid,
        user: user_uuid,
        parents: source_plates.map(&:uuid)
      )
    end

    def source_plates
      @source_plates ||= Sequencescape::Api::V2::Plate.find_all(
        { barcode: barcodes },
        includes: 'purpose,parents,wells.aliquots.request,wells.requests_as_source'
      )
    end
  end
end
