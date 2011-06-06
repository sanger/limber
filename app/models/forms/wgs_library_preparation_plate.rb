module Forms
  class WgsLibraryPreparationPlate < CreationForm
    PARTIAL = 'robot'

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
