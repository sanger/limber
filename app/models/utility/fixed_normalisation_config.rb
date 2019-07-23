# frozen_string_literal: true

module Utility
  # Handles the fixed normalisation plate creation config functions.
  class FixedNormalisationConfig
    include ActiveModel::Model
    require 'bigdecimal'

    attr_reader :config

    def initialize(config)
      @config = config
    end

    # This precision number could be extracted from config yml in future if needed.
    def number_decimal_places
      3
    end

    # Converts the string number to a big decimal
    def to_bigdecimal(s_number)
      BigDecimal(s_number, number_decimal_places)
    end

    # Returns source volume from the config ynl
    def source_volume
      to_bigdecimal(@config['source_volume_ul'])
    end

    # Returns diluent volume from the config ynl
    def diluent_volume
      to_bigdecimal(@config['diluent_volume_ul'])
    end

    # Returns the multiplication factor for the source (parent) plate
    def source_multiplication_factor
      source_volume
    end

    # Returns the multiplication factor for the destination (child) plate
    def dest_multiplication_factor
      source_volume + diluent_volume
    end
  end
end
