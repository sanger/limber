# frozen_string_literal: true

module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file'
  #
  # Class CsvRow provides a simple wrapper for handling and validating
  # individual CSV rows
  #
  class PcrCyclesBinnedPlate::CsvFile::Row
    include ActiveModel::Validations

    # MISSING_SOURCE = 'is blank in %s but a destination has been specified. '\
    #                  'Either supply a source, or remove the destination.'
    # MISSING_VOLUME = 'is blank in %s but a destination has been specified. '\
    #                  'Either supply a positive volume, or remove the destination.'
    # NEGATIVE_VOLUME = 'is %%{value} in %s but a destination has been specified. '\
    #                   'Either supply a positive volume, or remove the destination.'

    attr_reader :header, :well, :concentration, :sanger_sample_id, :supplier_sample_name,
    :input_amount_available, :input_amount_desired, :sample_volume, :diluent_volume,
    :pcr_cycles, :submit_for_sequencing, :sub_pool, :coverage, :index

    validates :well, inclusion: { in: WellHelpers.column_order, message: "contains an invalid well name: '%{value}'" }

    validate :input_amount_desired_within_expected_range?
    validate :sample_volume_within_expected_range?
    validate :diluent_volume_within_expected_range?
    validate :pcr_cycles_within_expected_range?
    # validate :submit_for_sequencing_has_expected_value?
    validate :sub_pool_within_expected_range?
    # validate :coverage_is_positive?


    # :submit_for_sequencing_valid_values:
    # - 'Y'
    # - 'N'

    delegate :well_column, :concentration_column, :sanger_sample_id_column,
    :supplier_sample_name_column, :input_amount_available_column, :input_amount_desired_column,
    :sample_volume_column, :diluent_volume_column, :pcr_cycles_column,
    :submit_for_sequencing_column, :sub_pool_column, :coverage_column, to: :header

    def initialize(row_config, header, index, row_data)
      @row_config = row_config
      @header = header
      @index = index

      # We use %.to_i or .to_f to avoid converting nil to 0. This allows us to write less
      # confusing validation error messages.
      @well = (row_data[well_column] || '').strip.upcase
      @concentration = row_data[concentration_column]&.to_f
      @sanger_sample_id = row_data[sanger_sample_id_column]&.to_i
      @supplier_sample_name = (row_data[supplier_sample_name_column] || '').strip
      @input_amount_available = row_data[input_amount_available_column]&.to_f
      @input_amount_desired = row_data[input_amount_desired_column]&.to_f
      @sample_volume = row_data[sample_volume_column]&.to_f
      @diluent_volume = row_data[diluent_volume_column]&.to_f
      @pcr_cycles = row_data[pcr_cycles_column]&.to_i
      @submit_for_sequencing = (row_data[submit_for_sequencing_column] || '').strip.upcase
      @sub_pool = row_data[sub_pool_column]&.to_i
      @coverage = row_data[coverage_column]&.to_i
    end

    def to_s
      if well.present?
        "row #{index} [#{well}]"
      else
        "row #{index}"
      end
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
      in_range?(
        'sample_volume',
        sample_volume,
        @row_config.sample_volume_min,
        @row_config.sample_volume_max
      )
    end

    def diluent_volume_within_expected_range?
      in_range?(
        'diluent_volume',
        diluent_volume,
        @row_config.diluent_volume_min,
        @row_config.diluent_volume_max
      )
    end

    def pcr_cycles_within_expected_range?
      in_range?(
        'pcr_cycles',
        pcr_cycles,
        @row_config.pcr_cycles_min,
        @row_config.pcr_cycles_max
      )
    end

    def sub_pool_within_expected_range?
      if submit_for_sequencing == 'Y'
        in_range?(
          'sub_pool',
          sub_pool,
          @row_config.sub_pool_min,
          @row_config.sub_pool_max
        )
      else
        # expect sub-pool field to be blank, possible mistake if not

      end
    end

    # In range method using min/max values from the row config
    #
    #
    #
    def in_range?(field_name, field_value, min, max)
      result = (min..max).cover? field_value
      puts "min = #{min}"
      puts "max = #{max}"
      puts "field_name = #{field_name}"
      puts "field_value = #{field_value}"
      puts "result = #{result}"
      puts '---------------'
      unless result
        msg_fmt = 'contains a value that is out of range (%s to %s), in well: %s'
        msg = msg_fmt % [min, max, well]
        puts "msg = #{msg}"
        puts '---------------'
        errors.add(field_name, msg)
      end
      result
    end

    def empty?
      sanger_sample_id.blank?
    end
  end
end
