module Forms

  class CreationForm
    extend ActiveModel::Naming
    include ActiveModel::Validations

    def persisted?
      false
    end

    PARTIAL = 'new'

    ATTRIBUTES = [:api, :plate_purpose_uuid, :parent_uuid, :notes, :user]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    # validates_presence_of *ATTRIBUTES

    def child
      plate_creation.try(:child) || :child_not_created
    end

    def child_plate_purpose
      @child_plate_purpose ||= api.plate_purpose.find(plate_purpose_uuid)
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end

    def save
      return false unless valid?

      create_objects!
    end

    def create_objects!
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

  class WgsFragmentationPlate < CreationForm; end

  class WgsFragmentationPurificationPlate < CreationForm; end

  class QcPlate < CreationForm; end

  class WgsLibraryPreparationPlate < CreationForm; end

  class WgsAmplifiedLibraryPlate < CreationForm; end

  class WgsPooledAmplifiedLibraryPlate < CreationForm; end
end
