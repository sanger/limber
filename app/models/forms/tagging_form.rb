module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'tagging'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :tag_layout_template_uuid]

    validates_presence_of *self.attributes

    def tag_layout_template_uuids
      @tag_layout_template_uuids ||= api.tag_layout_template.all
    end

    def create_objects!
      create_plate! do |plate|
        api.tag_layout_template.find(tag_layout_template_uuid).create!(:plate => plate.uuid)
      end
    end
    private :create_objects!
  end
end
