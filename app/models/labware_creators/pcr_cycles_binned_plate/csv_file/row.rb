# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file'
  #
  # Class CsvRow provides a simple wrapper for handling and validating
  # individual CSV rows
  #
  class PcrCyclesBinnedPlate::CsvFile::Row
    include ActiveModel::Validations

    IN_RANGE = 'contains a value that is out of range (%s to %s), in well: %s'
    SUB_POOL_NOT_BLANK = 'has a value when Submit for Sequencing is N, it should be empty, in well: %s'
    SUBMIT_FOR_SEQ_INVALID = 'has an unrecogised value, should be Y or N, in well: %s'
    COVERAGE_MISSING = 'is missing in %s but should be present when Submit for Sequencing is Y'
    COVERAGE_NEGATIVE = 'is negative in %s but should be a positive value'

    attr_reader :header, :index

    validates :well, inclusion: { in: WellHelpers.column_order, message: "contains an invalid well name: '%{value}'" }

    validate :input_amount_desired_within_expected_range?
    validate :sample_volume_within_expected_range?
    validate :diluent_volume_within_expected_range?
    validate :pcr_cycles_within_expected_range?
    validate :submit_for_sequencing_has_expected_value?
    validate :sub_pool_within_expected_range?
    validates :coverage,
              presence: {
                message: ->(object, _data) { COVERAGE_MISSING % object }
              },
              numericality: {
                greater_than: 0,
                message: ->(object, _data) { COVERAGE_NEGATIVE % object }
              },
              unless: -> { empty? || !submitting_for_sequencing? }

    delegate :well_column, :concentration_column, :sanger_sample_id_column,
             :supplier_sample_name_column, :input_amount_available_column,
             :input_amount_desired_column, :sample_volume_column, :diluent_volume_column,
             :pcr_cycles_column, :submit_for_sequencing_column, :sub_pool_column,
             :coverage_column, to: :header

    def initialize(row_config, header, index, row_data)
      @row_config = row_config
      @header = header
      @index = index
      @row_data = row_data
    end

    def well
      (@row_data[well_column] || '').strip.upcase
    end

    def concentration
      @row_data[concentration_column]&.to_f
    end

    def sanger_sample_id
      @row_data[sanger_sample_id_column]&.to_i
    end

    def supplier_sample_name
      (@row_data[supplier_sample_name_column] || '').strip
    end

    def input_amount_available
      @row_data[input_amount_available_column]&.to_f
    end

    def input_amount_desired
      @row_data[input_amount_desired_column]&.to_f
    end

    def sample_volume
      @row_data[sample_volume_column]&.to_f
    end

    def diluent_volume
      @row_data[diluent_volume_column]&.to_f
    end

    def pcr_cycles
      @row_data[pcr_cycles_column]&.to_i
    end

    def submit_for_sequencing
      (@row_data[submit_for_sequencing_column] || '').strip.upcase
    end

    def submitting_for_sequencing?
      submit_for_sequencing == 'Y'
    end

    def sub_pool
      @row_data[sub_pool_column]&.to_i
    end

    def coverage
      @row_data[coverage_column]&.to_i
    end

    def to_s
      if well.present?
        "row #{index} [#{well}]"
      else
        "row #{index}"
      end
    end

    def input_amount_desired_within_expected_range?
      in_range?('input_amount_desired', input_amount_desired, @row_config.input_amount_desired_min, @row_config.input_amount_desired_max)
    end

    def sample_volume_within_expected_range?
      in_range?('sample_volume', sample_volume, @row_config.sample_volume_min, @row_config.sample_volume_max)
    end

    def diluent_volume_within_expected_range?
      in_range?('diluent_volume', diluent_volume, @row_config.diluent_volume_min, @row_config.diluent_volume_max)
    end

    def pcr_cycles_within_expected_range?
      in_range?('pcr_cycles', pcr_cycles, @row_config.pcr_cycles_min, @row_config.pcr_cycles_max)
    end

    def submit_for_sequencing_has_expected_value?
      return true if empty?

      return true if %w[Y N].include? submit_for_sequencing

      errors.add(submit_for_sequencing, format(SUBMIT_FOR_SEQ_INVALID, well))
    end

    def sub_pool_within_expected_range?
      return true if empty?

      # check the value is within range when we do expect a value to be present
      return in_range?('sub_pool', sub_pool, @row_config.sub_pool_min, @row_config.sub_pool_max) if submit_for_sequencing == 'Y'

      # expect sub-pool field to be blank, possible mistake by user if not
      return true if sub_pool.blank?

      # sub-pool is NOT blank and should be
      errors.add(sub_pool, format(SUB_POOL_NOT_BLANK, well))
      false
    end

    # Checks whether a row value it within the specified range using min/max values
    # from the row config
    #
    # field_name [string] The name of the field being validated
    # field_value [float or int] The value being tested
    # min/max [float or int] The minimum and maximum in the range
    #
    # @return [bool]
    def in_range?(field_name, field_value, min, max)
      return true if empty?

      result = (min..max).cover? field_value
      unless result
        msg = format(IN_RANGE, min, max, well)
        errors.add(field_name, msg)
      end
      result
    end

    def empty?
      sanger_sample_id.blank?
    end
  end
end
