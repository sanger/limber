# frozen_string_literal: true

module Presenters
  class UnknownPlateType < StandardError
    attr_reader :plate

    def errors
      "Unknown plate type #{plate.plate_purpose.name.inspect}. Perhaps you are using the wrong pipeline application?"
    end

    def suitable_labware
      false
    end

    def initialize(opts)
      @plate = opts[:labware]
    end
  end
end
