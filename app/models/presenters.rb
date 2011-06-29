module Presenters
  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        write_inheritable_attribute :page, 'show'
      end
    end

    def save!
    end
  end

  class PlatePresenter
    include Presenter
    include PlateWalking

    write_inheritable_attribute :attributes, [ :api, :plate ]

    class_inheritable_reader :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'lab_ware/aliquot'

    def plate_to_walk
      self.plate
    end

    def lab_ware
      self.plate
    end

    def lab_ware_form_details(view)
      { :url => view.pulldown_plate_path(self.plate), :as  => :plate }
    end

    class UnknownPlateType < StandardError
      attr_reader :plate

      def initialize(plate)
        super("Unknown plate type #{plate.plate_purpose.name.inspect}")
        @plate = plate
      end
    end

    def self.lookup_for(plate)
      plate_details = Settings.plate_purposes[plate.plate_purpose.uuid] or raise UnknownPlateType, plate
      plate_details[:presenter_class].constantize
    end
  end
end
