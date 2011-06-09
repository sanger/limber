module Forms
  class WgsLibraryPcrPlate < CreationForm
    PARTIAL    = 'tagging'
    ATTRIBUTES = [:api, :plate_purpose_uuid, :plate_uuid, :tag_layout_template_uuid]

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
      # api.tag_layout_template.find()
      # Find and create stuff...

      @plate_creation = api.plate_creation.create!(
        :parent              => parent,
        :child_plate_purpose => child_plate_purpose
        # :user_uuid           => user_uuid
      )


    rescue
      false
    end
    private :create_objects!
  end
end
