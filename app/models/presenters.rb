module Presenters
  class PlatePresenter
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    class_inheritable_reader :page
    write_inheritable_attribute :page, 'show'

    class_inheritable_reader :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'aliquot'

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

    def wells_by_row
      @plate.wells.inject(Hash.new {|h,k| h[k]=[]}) do |h,well|
        h[well.location.sub(/\d+/,'')] << well; h
      end
    end
  end

  def self.lookup_for(plate)
    $stderr.puts plate.plate_purpose.uuid
    Settings.plate_purposes[plate.plate_purpose.uuid][:presenter_class].constantize
  end
end
