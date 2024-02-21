# frozen_string_literal: true

module Utility
  # This version is for the Duplex Seq pipeline.
  class PcrCyclesForDuplexSeqCsvFileUploadConfig < PcrCyclesCsvFileUploadConfigBase
    PIPELINE_SPECIFIC_CONFIG_VARIABLES = { sub_pool_min: 'to_i', sub_pool_max: 'to_i' }.freeze

    def initialize_pipeline_specific_methods
      PIPELINE_SPECIFIC_CONFIG_VARIABLES.each { |k, v| create_method(k) { @csv_file_config[k].send(v) } }
    end

    def submit_for_sequencing_valid_values
      @csv_file_config.fetch(:submit_for_sequencing_valid_values, []).map
    end
  end
end
