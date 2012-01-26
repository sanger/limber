module Forms
  class BaitingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, "baiting"
    class_inheritable_reader :aliquot_partial
    write_inheritable_attribute :aliquot_partial, "plates/baited_aliquot"

    def plate
      self.parent
    end

    def bait_library_layout_preview
      @bait_library_layout_preview ||= api.bait_library_layout.preview!(
        :plate => parent_uuid,
        :user => user_uuid
      ).layout
    end

    def create_objects!
      create_plate! do |plate|
        api.bait_library_layout.create!(
          :plate => plate.uuid,
          :user  => user_uuid
        )
      end
    end

    def baits
      Hash[wells.map { |w| [w.bait, w] if w.bait.present? }.compact].values
    end

    def wells
      plate.locations_in_rows.map do |location|
        location = "#{r}#{c}"
        bait     = bait_library_layout_preview[location]
        aliquot  = bait # Fudge, will be nil if no bait

        Hashie::Mash.new(
          :location => location,
          :bait     => bait,
          :aliquots => [aliquot].compact
        )
      end
    end

    def wells_by_row
      PlateWalking::Walker.new(plate, wells)
    end
  end
end
