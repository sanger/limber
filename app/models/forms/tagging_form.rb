module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'tagging'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :tag_layout_template_uuid, :user_uuid]

    validates_presence_of *self.attributes

    def tag_layout_templates
      return @tag_layout_template if @tag_layout_template.present?
      maximum_pool_size = plate.pools.map(&:last).map!(&:size).max

      @tag_layout_templates = api.tag_layout_template.all.select do |template|
         template.tag_group.tags.size >= maximum_pool_size
      end
    end

    def tag_groups
      Hash[ tag_layout_templates.map { |layout| [ layout.name, tags_by_row(layout) ] } ]
    end

    # Creates a 96 element array of tags from the tag array passed in.
    # If the input is longer than 96 it takes the first 96 if shorter
    # it loops the elements to make up the 96.
    def first_96_tags(tags)
      Array.new(96) { |i| tags[(i % tags.size)] }
    end

    def tags_by_column(tags)
      first_96_tags(tags).each_slice(8).to_a
    end

    def tag_ids(layout)
      layout.tag_group.tags.keys.map!(&:to_i).sort
    end

    def tags_by_row(layout)
      tags_by_column(tag_ids(layout)).transpose.flatten
    end

    def create_objects!
      create_plate! do |plate|
        api.tag_layout_template.find(tag_layout_template_uuid).create!(
          :plate => plate.uuid,
          :user  => user_uuid
        )
      end
    end
    private :create_objects!
  end
end
