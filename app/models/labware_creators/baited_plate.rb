# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # In ISC pipeline.
  # Provides a user with a preview of the expected bait library layout
  # Creates a new plate, which is a stamp of the parent.
  # Applies the bait library to the aliquots of the plate in accordance with the
  # baits specified at submission.
  class BaitedPlate < StampedPlate
    include SupportParent::PlateOnly
    include LabwareCreators::CustomPage

    self.page = 'baited_plate'
    self.aliquot_partial = 'baited_aliquot'

    delegate :number_of_columns, :number_of_rows, :size, to: :plate

    def plate
      parent
    end

    def bait_library_layout_preview
      @bait_library_layout_preview ||= api.bait_library_layout.preview!(
        plate: parent_uuid,
        user: user_uuid
      ).layout
    end

    def create_labware!
      create_plate_with_standard_transfer! do |child|
        api.bait_library_layout.create!(
          plate: child.uuid,
          user: user_uuid
        )
      end
    end

    def baits
      wells.select { |w| w.bait.present? }
    end

    def wells
      parent.locations_in_rows.map do |location|
        bait     = bait_library_layout_preview[location]
        aliquot  = bait # Fudge, will be nil if no bait

        OpenStruct.new(
          location: location,
          bait: bait,
          aliquots: [aliquot].compact,
          pool_id: nil
        )
      end
    end

    def wells_by_row
      PlateWalking::Walker.new(parent, wells)
    end
  end
end
