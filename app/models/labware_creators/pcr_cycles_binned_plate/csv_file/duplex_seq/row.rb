# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file_for_duplex_seq'

  module PcrCyclesBinnedPlate::CsvFile
    #
    # This version of the row is for the Duplex Seq pipeline.
    #
    class DuplexSeq::Row < RowBase
      include ActiveModel::Validations

      SUB_POOL_NOT_BLANK = 'has a value when Submit for Sequencing is N, it should be empty, in %s'
      SUBMIT_FOR_SEQ_INVALID = 'is empty or has an unrecognised value (should be Y or N), in %s'
      COVERAGE_MISSING = 'is missing but should be present when Submit for Sequencing is Y, in %s'
      COVERAGE_NEGATIVE = 'is negative but should be a positive value, in %s'

      attr_reader :submit_for_sequencing, :sub_pool, :coverage

      validate :submit_for_sequencing_has_expected_value
      validate :sub_pool_within_expected_range
      validates :coverage,
                presence: {
                  message: ->(object, _data) { COVERAGE_MISSING % object }
                },
                numericality: {
                  greater_than: 0,
                  message: ->(object, _data) { COVERAGE_NEGATIVE % object }
                },
                unless: -> { empty? || !submit_for_sequencing? }

      delegate :submit_for_sequencing_column, :sub_pool_column, :coverage_column, to: :header

      def initialize_pipeline_specific_columns
        @submit_for_sequencing_as_string = @row_data[submit_for_sequencing_column]&.strip&.upcase
        @sub_pool = @row_data[sub_pool_column]&.strip&.to_i
        @coverage = @row_data[coverage_column]&.strip&.to_i
      end

      def submit_for_sequencing?
        @submit_for_sequencing ||= (@submit_for_sequencing_as_string == 'Y')
      end

      def submit_for_sequencing_has_expected_value
        return if empty?

        return if %w[Y N].include? @submit_for_sequencing_as_string

        errors.add('submit_for_sequencing', format(SUBMIT_FOR_SEQ_INVALID, to_s))
      end

      def sub_pool_within_expected_range
        return if empty?

        # check the value is within range when we do expect a value to be present
        if submit_for_sequencing?
          in_range('sub_pool', sub_pool, @row_config.sub_pool_min, @row_config.sub_pool_max)
        else
          # expect sub-pool field to be blank, possible mistake by user if not
          return if sub_pool.blank?

          # sub-pool is NOT blank and should be
          errors.add('sub_pool', format(SUB_POOL_NOT_BLANK, to_s))
        end
      end
    end
  end
end
