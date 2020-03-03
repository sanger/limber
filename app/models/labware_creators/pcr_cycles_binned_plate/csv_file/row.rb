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

    # validates :source,
    #           presence: {
    #             message: ->(object, _data) { MISSING_SOURCE % object }
    #           },
    #           unless: :empty?

    # validates :volume,
    #           presence: {
    #             message: ->(object, _data) { MISSING_VOLUME % object }
    #           },
    #           numericality: {
    #             greater_than: 0,
    #             message: ->(object, _data) { NEGATIVE_VOLUME % object }
    #           },
    #           unless: :empty?

    # validates :source, inclusion: { in: WellHelpers.column_order, message: "contains an invalid well name: '%{value}'" }

    delegate :well_column, :concentration_column, :sanger_sample_id_column,
    :supplier_sample_name_column, :input_amount_available_column, :input_amount_desired_column,
    :sample_volume_column, :diluent_volume_column, :pcr_cycles_column,
    :submit_for_sequencing_column, :sub_pool_column, :coverage_column, to: :header

    def initialize(header, index, row_data)
      @header = header
      @index = index

      # We use %.to_i or .to_f to avoid converting nil to 0. This allows us to write less
      # confusing validation error messages.

      @well = (row_data[well_column] || '').strip.upcase
      @concentration = row_data[concentration_column]&.to_f
      @sanger_sample_id = row_data[sanger_sample_id_column]&.to_i
      @supplier_sample_name = (row_data[supplier_sample_name_column] || '').strip.upcase
      @input_amount_available = row_data[input_amount_available_column]&.to_f
      @input_amount_desired = row_data[input_amount_desired_column]&.to_f
      @sample_volume = row_data[sample_volume_column]&.to_f
      @diluent_volume = row_data[diluent_volume_column]&.to_f
      @pcr_cycles = row_data[pcr_cycles_column]&.to_i
      @submit_for_sequencing = (row_data[submit_for_sequencing_column] || '').strip.upcase # TODO: needs to be Y/N
      @sub_pool = row_data[sub_pool_column]&.to_i
      @coverage = row_data[coverage_column]&.to_f # TODO: clarify if decimal
    end

    def to_s
      if well.present?
        "row #{index} [#{well}]"
      else
        "row #{index}"
      end
    end

    # def empty?
    #   destination.blank?
    # end
  end
end
