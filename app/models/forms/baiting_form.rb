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
      @bait_library_layout_preview ||= api.bait_library_layout.preview!(:plate => parent_uuid).layout
    end

    def create_objects!
      create_plate! do |plate|
        api.bait_library_layout.create!(:plate => plate.uuid)
      end
    end

    def baits
      Hash[wells.map { |w| [w.bait, w] }].values
    end

    def wells
      bait_library_layout_preview.sort.map do |well|
        Hashie::Mash.new(
          :location => well[0],
          :bait     => well[1],
          :aliquots => [:an_aliquot]
        )
      end
    end

    def wells_by_row
      @wells_by_row ||= wells.inject(Hash.new {|h,k| h[k]=[]}) do |h,well|
        h[well.location.sub(/\d+/,'')] << well; h
      end.sort

      @wells_by_row.each do |row|
        row.last.sort! { |a,b| a.location.sub(/\D+/,'').to_i <=> b.location.sub(/\D+/,'').to_i }
      end

      @wells_by_row
    end
  end
end
