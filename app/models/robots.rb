module Robots
  class Robot
    include Forms::Form

    class Bed
      include Forms::Form

      class BedError < StandardError; end
      # Our robot has beds/rack-spaces
      attr_reader :plate

      class_inheritable_reader :attributes
      write_inheritable_attribute :attributes, [:api, :user_uuid, :purpose, :state, :label, :parent, :target_state]

      def has_transition?
        @target_state.present?
      end

      def transition
        return if target_state.nil? || plate.nil? # We have nothing to do
        StateChangers.lookup_for(plate.plate_purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(target_state)
      end

      def valid?
        case
        when plate.nil? # The bed is empty or untested
          return true
        when !states.include?(plate.state) # The plate is in the wrong state
          raise BedError, "Plate #{plate.barcode.ean13} is #{plate.state} when it should be #{states.join(', ')}."
        when plate.plate_purpose.uuid != Settings.purpose_uuids[purpose]
          raise BedError, "Plate #{plate.barcode.ean13} is not a #{purpose}."
        else
          true
        end
      end

      def load(barcode)
        @plate = api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode) unless barcode.nil?
      end

    end

    def self.find(options)
      robot_settings = Settings.robots[options[:name]]
      raise ActionController::RoutingError.new("Robot #{options[:name]} Not Found") if robot_settings.nil?
      Robot.new(robot_settings.merge(options))
    end

    class_inheritable_reader :attributes
    write_inheritable_attribute :attributes, [:api, :user_uuid, :layout, :beds, :name]

    def beds=(new_beds)
      beds = ActiveSupport::OrderedHash.new
      new_beds.sort_by {|id,bed| bed.order }.each do |id,bed|
        beds[id] = Bed.new(bed.merge({:api=>api, :user_uuid=>user_uuid }))
      end
      @beds = beds
    end
    private :beds=

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.has_transition?
        bed.valid?
      end
      beds.each(&:transition)
    end

    def verify(bed_contents)
      bed_contents.each do |bed_id,plate_barcode|
        beds[bed_id].load(plate_barcode)
        bed_contents[bed_id] = beds[bed_id].valid?
      end
      {:beds=>bed_contents,:valid=>bed_contents.all?{|_,v| v}}
    end

  end

end
