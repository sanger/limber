module Forms
  class WgsLibraryPlate < CreationForm
    PARTIAL    = 'robot'
    ATTRIBUTES = [:api, :plate_purpose_uuid, :plate_uuid, :transfer_template_uuid]
    
    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    validates_presence_of *ATTRIBUTES
    def transfer_template_uuids
      @transfer_template_uuids ||= api.transfer_template.all
    end
    
    def create_objects
      # api.transfer_template.find()

      @plate_creation = api.plate_creation.create!(
        :parent              => parent,
        :child_plate_purpose => child_plate_purpose
        # :user_uuid           => user_uuid
      )

    rescue
      false
    end
    private :create_objects    
  end
end
