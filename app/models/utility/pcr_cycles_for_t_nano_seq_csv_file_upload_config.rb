# frozen_string_literal: true

module Utility
  # This version is for the Targeted NanoSeq pipeline.
  class PcrCyclesForTNanoSeqCsvFileUploadConfig < PcrCyclesCsvFileUploadConfigBase
    PIPELINE_SPECIFIC_CONFIG_VARIABLES = {}.freeze

    def initialize_pipeline_specific_methods
      PIPELINE_SPECIFIC_CONFIG_VARIABLES.each { |k, v| create_method(k) { @csv_file_config[k].send(v) } }
    end
  end
end
