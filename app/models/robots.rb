module Robots
  class Robot
    include Forms::Form

    class Bed
      include Forms::Form

      class BedError < StandardError; end
      # Our robot has beds/rack-spaces
      attr_reader :plate, :error_message

      class_inheritable_reader :attributes
      write_inheritable_attribute :attributes, [:api, :user_uuid, :purpose, :states, :label, :parent, :target_state, :robot]

      def has_transition?
        @target_state.present?
      end

      def transition
        return if target_state.nil? || plate.nil? # We have nothing to do
        StateChangers.lookup_for(plate.plate_purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(target_state,"Robot #{robot.name} started")
      end

      def error(message)
        @error_message = "Plate #{plate.barcode.ean13} is #{plate.state} when it should be #{states.join(', ')}."
        false
      end
      private :error


      def valid?
        case
        when plate.nil? # The bed is empty or untested
          return true
        when !states.include?(plate.state) # The plate is in the wrong state
          error("Plate #{plate.barcode.ean13} is #{plate.state} when it should be #{states.join(', ')}.")
        when plate.plate_purpose.uuid != Settings.purpose_uuids[purpose]
          error("Plate #{plate.barcode.ean13} is not a #{purpose}.")
        else
          true
        end
      end

      def load(barcode)
        @plate = api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode) unless barcode.nil?
      end

      def parent_plate
        return nil if plate.nil?
        api.search.find(Settings.searches['Find source assets by destination asset barcode']).first(:barcode => plate.barcode.ean13)
      end

    end

    class InvalidBed
      def load(_)
      end
      def valid?
        false
      end
    end

    def self.find(options)
      robot_settings = Settings.robots[options[:location]]
      raise ActionController::RoutingError.new("Location #{options[:location]} Not Found") if robot_settings.nil?
      robot_settings = robot_settings[options[:id]]
      raise ActionController::RoutingError.new("Robot #{options[:name]} Not Found") if robot_settings.nil?
      Robot.new(robot_settings.merge(options))
    end

    class_inheritable_reader :attributes
    write_inheritable_attribute :attributes, [:api, :user_uuid, :layout, :beds, :name, :id, :location]

    def beds=(new_beds)
      beds = ActiveSupport::OrderedHash.new(InvalidBed.new)
      new_beds.sort_by {|id,bed| bed.order }.each do |id,bed|
        beds[id] = Bed.new(bed.merge({:api=>api, :user_uuid=>user_uuid, :robot=>self }))
      end
      @beds = beds
    end
    private :beds=

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.has_transition?
        bed.valid? or raise BedError, bed.error_message
      end
      beds.values.each(&:transition)
    end

    def verify(bed_contents)
      valid_plates = Hash[bed_contents.map do |bed_id,plate_barcode|
        beds[bed_id].load(plate_barcode)
        [bed_id, beds[bed_id].valid?]
      end]
      valid_parents = Hash[parents_and_position do |parent,position|
        beds[position].plate.try(:uuid) == parent.try(:uuid)
      end]
      verified = valid_plates.merge(valid_parents) {|k,v1,v2| v1 && v2 }
      bed_contents.keys.each {|k| verified[k] = false } unless plates_compatible?
      {:beds=>verified,:valid=>verified.all?{|_,v| v}}
    end

    def plates_compatible?
      puts beds.map {|id,bed| bed.plate.label.prefix unless bed.plate.nil? }.compact.uniq
      beds.map {|id,bed| bed.plate.label.prefix unless bed.plate.nil?}.compact.uniq.count == 1
    end

    def parents_and_position
      beds.map do |id, bed|
        next if bed.parent.nil?
        result = yield(bed.parent_plate,bed.parent)
        [id,result]
      end
    end
    private :parents_and_position

  end

end
