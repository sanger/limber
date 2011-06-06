module Forms
  
  class CreationForm
    extend ActiveModel::Naming
    include ActiveModel::Validations
    
    def persisted?
      false
    end
    
    PARTIAL = 'new'
    
    # TODO :plate_id should be :plate_uuid but needs the route fixed
    ATTRIBUTES = [:api, :plate_purpose_uuid, :plate_uuid]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    validates_presence_of *ATTRIBUTES
    
    def child
      plate_creation.try(:child) || :child_not_created
    end
    
    def child_plate_purpose
      @child_plate_purpose ||= api.plate_purpose.find(plate_purpose_uuid)
    end
    
    def parent
      @parent ||= api.plate.find(plate_uuid)
    end

    def save
      return false unless valid?

      if create_objects
        true
      else
        false
      end
    end

    def create_objects
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
  
  class WgsFragmentationPlate < CreationForm; end
  
  class WgsFragmentationPurificationPlate < CreationForm; end
  
  class QcPlate < CreationForm; end
  
  class WgsLibraryPlate < CreationForm; end
  
  class WgsLibraryPcrPlate < CreationForm; end
  
  class WgsAmplifiedLibraryPlate < CreationForm; end
  
  class WgsPooledAmplifiedLibraryPlate < CreationForm; end
end
