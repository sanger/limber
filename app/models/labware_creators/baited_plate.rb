# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  class BaitedPlate < Base
    include SupportParent::PlateOnly
    include LabwareCreators::CustomPage

    self.page = 'baited_plate'
    class_attribute :aliquot_partial
    self.aliquot_partial = 'plates/baited_aliquot'

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
      create_plate_with_standard_transfer! do |plate|
        api.bait_library_layout.create!(
          plate: plate.uuid,
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

        Hashie::Mash.new(
          location: location,
          bait: bait,
          aliquots: [aliquot].compact
        )
      end
    end

    def wells_by_row
      PlateWalking::Walker.new(parent, wells)
    end
  end
end
