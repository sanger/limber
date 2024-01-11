# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file'

  #
  # This version of the row is for the Targeted NanoSeq pipeline.
  #
  class PcrCyclesBinnedPlate::CsvFile::RowForTNanoSeq
    include ActiveModel::Validations

    IN_RANGE = 'is empty or contains a value that is out of range (%s to %s), in %s'
    WELL_NOT_RECOGNISED = 'contains an invalid well name: %s'
    HYB_PANEL_MISSING = 'is empty, in %s'

    attr_reader :header,
                :well,
                :concentration,
                :sanger_sample_id,
                :supplier_sample_name,
                :input_amount_available,
                :input_amount_desired,
                :sample_volume,
                :diluent_volume,
                :pcr_cycles,
                :hyb_panel,
                :index

    validates :well,
              inclusion: {
                in: WellHelpers.column_order,
                message: ->(object, _data) { WELL_NOT_RECOGNISED % object }
              },
              unless: :empty?
    validate :input_amount_desired_within_expected_range?
    validate :sample_volume_within_expected_range?
    validate :diluent_volume_within_expected_range?
    validate :pcr_cycles_within_expected_range?
    validate :hyb_panel_is_present?
    delegate :well_column,
             :concentration_column,
             :sanger_sample_id_column,
             :supplier_sample_name_column,
             :input_amount_available_column,
             :input_amount_desired_column,
             :sample_volume_column,
             :diluent_volume_column,
             :pcr_cycles_column,
             :hyb_panel_column,
             to: :header

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    def initialize(row_config, header, index, row_data)
      @row_config = row_config
      @header = header
      @index = index
      @row_data = row_data

      # initialize supplied fields
      @well = (@row_data[well_column] || '').strip.upcase
      @concentration = @row_data[concentration_column]&.strip&.to_f
      @sanger_sample_id = @row_data[sanger_sample_id_column]&.strip
      @supplier_sample_name = (@row_data[supplier_sample_name_column])&.strip
      @input_amount_available = @row_data[input_amount_available_column]&.strip&.to_f

      # initialize customer fields
      @input_amount_desired = @row_data[input_amount_desired_column]&.strip&.to_f
      @sample_volume = @row_data[sample_volume_column]&.strip&.to_f
      @diluent_volume = @row_data[diluent_volume_column]&.strip&.to_f
      @pcr_cycles = @row_data[pcr_cycles_column]&.strip&.to_i
      @hyb_panel = @row_data[hyb_panel_column]&.strip
    end

    # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

    def to_s
      @well.present? ? "row #{index + 2} [#{@well}]" : "row #{index + 2}"
    end

    def input_amount_desired_within_expected_range?
      in_range?(
        'input_amount_desired',
        input_amount_desired,
        @row_config.input_amount_desired_min,
        @row_config.input_amount_desired_max
      )
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

    # Checks whether the Hyb Panel column is filled in
    def hyb_panel_is_present?
      return true if empty?

      # TODO: can we validate the hyb panel value? Does not appear to be tracked in LIMS.
      result = hyb_panel.present?
      unless result
        msg = format(HYB_PANEL_MISSING, to_s)
        errors.add('hyb_panel', msg)
      end
      result
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
        msg = format(IN_RANGE, min, max, to_s)
        errors.add(field_name, msg)
      end
      result
    end

    def empty?
      @row_data.empty? || @row_data.compact.empty? || sanger_sample_id.blank?
    end
  end
end
