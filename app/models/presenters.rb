module Presenters
   class PlatePresenter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations


    ATTRIBUTES = [:api, :plate]

    attr_accessor *ATTRIBUTES

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end

    end

    def persisted?
      false
    end

    def save!
    end
  end


  def self.lookup_presenter(plate)
    PresenterLookUp.lookup(plate.plate_purpose.uuid)
  end

end
