module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'tagging'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :tag_layout_template_uuid, :user_uuid]

    validates_presence_of *self.attributes

    def tag_layout_templates
      return @tag_layout_template if @tag_layout_template.present?
      maximum_pool_size = plate.pools.map(&:last).map(&:size).max

      @tag_layout_templates = api.tag_layout_template.all.select do |template|
         template.tag_group.tags.size >= maximum_pool_size
      end
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
