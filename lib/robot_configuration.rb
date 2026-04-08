# frozen_string_literal: true

##
module RobotConfiguration
  BedOrCar = Struct.new(:barcode, :name)

  module BedHelpers # rubocop:todo Style/Documentation
    def bed(number)
      barcode = SBCF::SangerBarcode.new(prefix: 'BD', number: number)
      ean13 = barcode.machine_barcode.to_s
      BedOrCar.new(ean13, "Bed #{number}")
    end

    def car(position)
      number = position.tr(',', '').to_i
      barcode = SBCF::SangerBarcode.new(prefix: 'BD', number: number)
      ean13 = barcode.machine_barcode.to_s
      BedOrCar.new(ean13, "Carousel #{position}")
    end
  end

  class Register # rubocop:todo Style/Documentation
    include BedHelpers

    def self.configure(&)
      register = new
      register.instance_eval(&)
      register.configuration
    end

    def custom_robot(key, hash)
      @robots[key] = hash
    end

    def bravo_robot(transition_to: 'passed', verify_robot: false, require_robot: false, &)
      simple_robot('bravo', transition_to:, verify_robot:, require_robot:, &)
    end

    def simple_robot(type, transition_to: 'passed', verify_robot: false, require_robot: false, &)
      added_robot = RobotConfiguration::Simple.new(type, transition_to, verify_robot, require_robot, &)
      @robots[added_robot.key] = added_robot.configuration
      added_robot
    end

    def initialize
      @robots = {}
    end

    def configuration
      @robots
    end
  end

  class Simple # rubocop:todo Style/Documentation
    include BedHelpers

    attr_reader :source_purpose,
                :target_purpose,
                :type,
                :target_state,
                :source_bed_state,
                :target_bed_state,
                :verify_robot,
                :require_robot,
                :source_shared_parent

    # rubocop:todo Style/OptionalBooleanParameter
    def initialize(type, target_state = 'passed', verify_robot = false, require_robot = false, &block)
      @verify_robot = verify_robot
      @require_robot = require_robot
      @type = type
      @target_state = target_state
      instance_eval(&block) if block
    end

    # rubocop:enable Style/OptionalBooleanParameter

    def from(source_purpose, bed, state = 'passed', shared_parent: false)
      @source_purpose = source_purpose
      @source_bed = bed
      @source_bed_state = state
      @source_shared_parent = shared_parent
    end

    def source_bed_name
      @source_bed.name
    end

    def source_bed_barcode
      @source_bed.barcode
    end

    def to(target_purpose, bed, state = 'pending')
      @target_purpose = target_purpose
      @target_bed = bed
      @target_bed_state = state
    end

    def target_bed_name
      @target_bed.name
    end

    def target_bed_barcode
      @target_bed.barcode
    end

    def name
      "#{type} #{source_purpose} => #{target_purpose}"
    end

    def key
      "#{type} #{source_purpose} to #{target_purpose}".parameterize
    end

    def configuration
      {
        name: name,
        verify_robot: verify_robot,
        require_robot: require_robot,
        beds: {
          source_bed_barcode => {
            purpose: source_purpose,
            states: [source_bed_state],
            label: source_bed_name,
            shared_parent: source_shared_parent
          },
          target_bed_barcode => {
            purpose: target_purpose,
            states: [target_bed_state],
            label: target_bed_name,
            parent: source_bed_barcode,
            target_state: target_state
          }
        }
      }
    end
  end
end
