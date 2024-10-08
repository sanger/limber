# frozen_string_literal: true

module Utility
  # Handles the extraction of dilution configuration functions for pcr cycle binning.
  class PcrCyclesCsvFileUploadConfigBase
    include ActiveModel::Model

    attr_reader :csv_file_config

    CONFIG_VARIABLES = {
      input_amount_desired_min: 'to_f',
      input_amount_desired_max: 'to_f',
      sample_volume_min: 'to_f',
      sample_volume_max: 'to_f',
      diluent_volume_min: 'to_f',
      diluent_volume_max: 'to_f',
      pcr_cycles_min: 'to_i',
      pcr_cycles_max: 'to_i'
    }.freeze

    def initialize(csv_file_config)
      @csv_file_config = csv_file_config
      CONFIG_VARIABLES.each { |k, v| create_method(k) { @csv_file_config[k].send(v) } }

      initialize_pipeline_specific_methods
    end

    def initialize_pipeline_specific_methods
      raise '#initialize_pipeline_specific_methods must be implemented on subclasses'
    end

    def create_method(name, &)
      self.class.send(:define_method, name, &)
    end

    def submit_for_sequencing_valid_values
      @csv_file_config.fetch(:submit_for_sequencing_valid_values, []).map
    end
  end
end
