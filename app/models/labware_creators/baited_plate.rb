# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # In ISC pipeline.
  # Provides a user with a preview of the expected bait library layout
  # Creates a new plate, which is a stamp of the parent.
  # Applies the bait library to the aliquots of the plate in accordance with the
  # baits specified at submission.
  class BaitedPlate < StampedPlate
    include CreatableFrom::PlateOnly
    include LabwareCreators::CustomPage

    self.page = 'baited_plate'
    self.aliquot_partial = 'baited_aliquot'
    self.style_class = 'baited'

    delegate :number_of_columns, :number_of_rows, :size, to: :plate

    Baits = Struct.new(:location, :bait, :aliquots, :pool_id)

    def plate
      parent
    end

    def bait_library_layout_preview
      @bait_library_layout_preview ||=
        Sequencescape::Api::V2::BaitLibraryLayout
          .preview(plate_uuid: parent_uuid, user_uuid: user_uuid)
          .first
          .well_layout
    end

    def create_labware!
      create_plate_with_standard_transfer! do |child|
        Sequencescape::Api::V2::BaitLibraryLayout.create!(plate_uuid: child.uuid, user_uuid: user_uuid)
      end
    end

    def baits
      wells.select { |w| w.bait.present? }
    end

    def wells
      parent.locations_in_rows.map do |location|
        bait = bait_library_layout_preview[location]
        aliquot = bait # Fudge, will be nil if no bait

        Baits.new(location, bait, [aliquot].compact, nil)
      end
    end

    def wells_by_row
      PlateWalking::Walker.new(parent, wells)
    end
  end
end
