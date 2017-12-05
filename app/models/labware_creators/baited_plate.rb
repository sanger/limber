# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  class BaitedPlate < Base
    include Form::CustomPage

    self.page = 'baited_plate'
    class_attribute :aliquot_partial
    self.aliquot_partial = 'plates/baited_aliquot'

    delegate :height, :width, :size, to: :plate

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
      Hash[wells.map { |w| [w.bait, w] if w.bait.present? }.compact].values
    end

    def wells
      plate.locations_in_rows.map do |location|
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
      PlateWalking::Walker.new(plate, wells)
    end
  end
end
