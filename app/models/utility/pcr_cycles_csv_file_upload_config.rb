# frozen_string_literal: true

module Utility
  # Handles the extraction of dilution configuration functions for pcr cycle binning.
  class PcrCyclesCsvFileUploadConfig
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
      pcr_cycles_max: 'to_i',
      sub_pool_min: 'to_i',
      sub_pool_max: 'to_i'
    }

    def initialize(csv_file_config)
      @csv_file_config = csv_file_config
      CONFIG_VARIABLES.each do |k,v|
        create_method(k) { @csv_file_config[k].send(v) }
      end
    end

    def create_method(name, &block)
      self.class.send(:define_method, name, &block)
    end

    def submit_for_sequencing_valid_values
      @csv_file_config.fetch(:submit_for_sequencing_valid_values, []).map
    end
  end
end
