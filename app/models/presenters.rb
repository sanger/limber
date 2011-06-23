module Presenters
   class PlatePresenter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    PAGE       = "show"
    ATTRIBUTES = [:api, :plate]

    attr_accessor *ATTRIBUTES

    def page
      self.class.const_get(:PAGE)
    end

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
