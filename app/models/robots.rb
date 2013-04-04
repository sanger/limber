module Robots
  class Robot
    include Forms::Form

    # Right, to keep things in order, our robot has a hash of beds and a layout
    # Layout => cytomat or bed, determines how the input boxes are displayed (css class?)
    # Beds => A simple hash formed from bed location. Could be an array, but hash means we can
    # have eg. A1
    # Bed => Each bed is created with a purpose, a state and an optional parent.
    class Bed

      class BedError < StandardError; end
      # Our robot has beds/rack-spaces
      attr_reader :state, :purpose, :parent, :label

      def initialize(purpose,state,label,parent=nil,transition_to=nil)
        @purpose       = purpose
        @state         = state
        @parent        = parent
        @label         = label
        @transition_to = transition_to
      end

      def has_transition?
        @transition_to.present?
      end

      def valid?
        # A final server side validation before we fire things off to Sequencescape?
        debugger
        case
        when plate.nil?
          return true # The bed is empty or untested
        when plate.state != state
          raise BedError, "Plate #{plate.barcode.ean13_barcode} is #{plate.state} when it should be #{state}"
        else
          true
        end
      end

      def load(barcode)
        debugger
        @plate = api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode) unless barcode.nil?
      end

    end

    def self.find(options)
      # Return a new robot with the appropriate set-up
      # Eventually we'll look this up in the config
      Robot.new(options.merge(
          :layout => 'cytomat',
          :beds   => {
            '1' => ['Post Shear','QC Complete','QC Plate A'],
            '2' => ['AL Libs','Pending', 'AL Libs Plate A', '1'],
            '3' => ['Lib PCR','Pending', 'Lib PCR Plate A', '2','fx_started'],
          }
        )
      )
    end

    # attr_reader :layout, :beds, :name, :api
    class_inheritable_reader :attributes
    write_inheritable_attribute :attributes, [:layout, :beds, :name, :api]

    def beds=(new_beds)
      beds = Hash.new
      new_beds.each do |id,bed|
        beds[id] = Bed.new(*bed)
      end
      @beds = beds
    end
    private :beds=

    def size
      beds.count
    end

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.has_transition?
        bed.valid?
      end
      beds.each(&:transition)
    end

  end

end
