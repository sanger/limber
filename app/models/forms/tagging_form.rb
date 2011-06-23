module Forms
  class TaggingForm < CreationForm
    PAGE       = 'tagging'
    ATTRIBUTES = [:api, :plate_purpose_uuid, :parent_uuid, :tag_layout_template_uuid]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    validates_presence_of *ATTRIBUTES
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
