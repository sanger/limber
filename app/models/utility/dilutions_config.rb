# frozen_string_literal: true

module Utility
  # Handles the extraction of dilution configuration functions.
  # Used by various dilution plate creators and their dilution calculators.
  class DilutionsConfig
    include ActiveModel::Model

    attr_reader :config

    def initialize(config)
      @config = config
    end

    # This precision number could be extracted from config yml in future if needed.
    def number_decimal_places
      3
    end

    # Returns library type from the config yml
    def library_type
      @config['library_type']
    end

    # Returns source volume from the config yml
    def source_volume
      @config['source_volume'].to_f
    end

    # Returns diluent volume from the config yml
    def diluent_volume
      @config['diluent_volume'].to_f
    end

    # Returns target amount in ng from the config yml
    def target_amount
      @config['target_amount_ng'].to_f
    end

    # Returns target volume from the config yml
    def target_volume
      @config['target_volume'].to_f
    end

    # Returns minimum source volume from the config yml
    def minimum_source_volume
      @config['minimum_source_volume'].to_f
    end

    # Returns the multiplication factor for the source (parent) plate
    def source_multiplication_factor
      source_volume
    end

    # Returns the multiplication factor for the destination (child) plate
    def dest_multiplication_factor
      source_volume + diluent_volume
    end

    # Returns number of distinct bins in the config yml
    def number_of_bins
      @config['bins'].size
    end

    # Returns the bins from the config yml
    def bins_template
      @bins_template ||= configure_bins_template
    end

    # Returns the bin minimum amount (ng) for a specific bin
    def bin_min(bin_template)
      (bin_template['min'] || 0.0).to_f
    end

    # Returns the bin maximum amount (ng) for a specific bin
    def bin_max(bin_template)
      (bin_template['max'] || Float::INFINITY).to_f
    end

    private

    # Returns an interpreted version of the bins configuration section with min max values
    def configure_bins_template
      @config['bins'].each_with_object([]) do |template, templates|
        templates << {
          'colour' => template['colour'],
          'pcr_cycles' => template['pcr_cycles'],
          'min' => bin_min(template),
          'max' => bin_max(template)
        }
      end
    end
  end
end
