# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Handles parsing and validation of Ultima balancing CSV files for the
# balanced pooled tube workflow.
#
# This class is responsible for:
#   - Extracting sample identifiers, barcodes, PF barcode reads, and mean coverage
#     values from the uploaded CSV file.
#   - Validating that the file follows the expected format:
#       • Filename must start with a numeric batch ID followed by an underscore
#         (e.g. "12345_rebalance.csv").
#       • Rows for "sample", "barcode", "pf_barcode_reads", and "mean_cvg" must exist.
#       • Row values must align in length with the number of samples.
#   - Providing accessors for the parsed data and batch ID.
#   - Running the balancing calculator to compute the balancing variables
#     for downstream processing.
# Errors during parsing or validation are captured and made available
# via ActiveModel validations.
module LabwareCreators
  require_dependency 'labware_creators/balanced_pooled_tube'

  # Parses and validates the Ultima balancing CSV file uploaded by the user.
  #
  # The file is expected to contain specific rows of data:
  #   - "sample"           → list of sample identifiers
  #   - "barcode"          → barcodes corresponding to samples
  #   - "pf_barcode_reads" → numeric values for PF barcode reads
  #   - "mean_cvg"         → numeric values for mean coverage
  #
  # The filename must begin with a numeric batch ID followed by an underscore,
  # e.g. "12345_rebalance.csv". The batch ID will be used when calculating
  # balancing variables.
  #
  class BalancedPooledTube::UltimaBalancingCsvFile
    include ActiveModel::Validations

    validate :validate_balancing_data

    SAMPLES_ROW = 'sample'
    BARCODE_ROW = 'barcode'
    PF_BARCODE_READS_ROW = 'pf_barcode_reads'
    MEAN_CVG_ROW = 'mean_cvg'

    attr_reader :batch_id, :samples, :barcodes, :pf_barcode_reads, :mean_cvg, :parse_error

    def initialize(file)
      @file = file
      init_balancing_data
    rescue StandardError => e
      @parse_error = e.message
    ensure
      file.rewind if file.respond_to?(:rewind)
    end

    # Runs the balancing calculator with the parsed CSV data.
    #
    # @return [Array<Hash>] calculated balancing variables per tag index
    def calculate_balancing_variables
      balancing_calculator = BalancedPooledTube::BalancingCalculator.new(
        @samples,
        @barcodes,
        @pf_barcode_reads,
        @mean_cvg,
        @batch_id
      )
      balancing_calculator.calculate
    end

    private

    def init_balancing_data
      start_index = nil
      CSV.read(@file).each do |row|
        row_title = row[0].to_s.strip.downcase
        start_index ||= find_start_index(row) if row_title == SAMPLES_ROW
        assign_balancing_data(row_title, row, start_index) if start_index
      end
    end

    # @param key [String] row key (e.g., "sample", "barcode")
    # @param row [Array<String>] CSV row
    # @param start_index [Integer, nil] starting column for values
    # @return [void]
    def assign_balancing_data(row_title, row, start_index)
      case row_title
      when SAMPLES_ROW
        @samples = row[start_index..]
      when BARCODE_ROW
        @barcodes = row[start_index..]
      when PF_BARCODE_READS_ROW
        @pf_barcode_reads = row[start_index..].map(&:to_d)
      when MEAN_CVG_ROW
        @mean_cvg = row[start_index..].map(&:to_d)
      end
    end

    # Finds the index of the first non-empty column after column 0.
    #
    # @param row [Array<String>] the CSV row
    # @return [Integer, nil] index of first non-empty cell after column 0
    # This is used to ignore column values not aligned with samples (TT, UNKN etc)
    def find_start_index(row)
      row.find_index.with_index { |val, i| i.positive? && val.present? }
    end

    def validate_file_name
      batch_id_str = @file.original_filename.split('_').first
      # Validate it contains only digits
      unless batch_id_str.match?(/\A\d+\z/)
        errors.add(:base, 'Filename must start with a numeric batch ID followed by an underscore')
        return
      end

      @batch_id = batch_id_str.to_i
    end

    # Validates that the file has the correct name format and required rows.
    #
    # @return [void]
    def validate_balancing_data
      validate_file_name
      validate_samples_row
      validate_row(BARCODE_ROW, @barcodes)
      validate_row(PF_BARCODE_READS_ROW, @pf_barcode_reads)
      validate_row(MEAN_CVG_ROW, @mean_cvg)
    end

    # Ensures the samples row exists and contains at least one sample.
    #
    # @return [void]
    def validate_samples_row
      return unless @samples.blank? || @samples.none?(&:present?)

      errors.add(:base, 'Samples row must have at least one sample')
    end

    # Ensures a row exists, has values, and matches the number of samples.
    #
    # @param name [String] row name (e.g. "barcode")
    # @param values [Array<String,Numeric>] row values
    # @return [void]
    def validate_row(name, values)
      if values.blank? || values.none?(&:present?)
        errors.add(:base, "#{name} row must have at least one value")
      elsif @samples && values.size != @samples.size
        errors.add(:base, "Number of #{name} values must match number of samples")
      end
    end
  end
end
