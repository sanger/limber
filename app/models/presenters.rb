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

    write_inheritable_attribute :attributes, [ :api, :plate ]

    class_inheritable_reader :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'lab_ware/aliquot'

    def wells_by_row
      @plate.wells.inject(Hash.new {|h,k| h[k]=[]}) do |h,well|
        h[well.location.sub(/\d+/,'')] << well; h
      end
    end

    def self.lookup_for(plate)
      Settings.plate_purposes[plate.plate_purpose.uuid][:presenter_class].constantize
    end
  end
end
