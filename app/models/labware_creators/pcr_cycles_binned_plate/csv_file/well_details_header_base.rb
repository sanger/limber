# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  #
  # Class WellDetailsHeader provides a simple wrapper for handling and validating
  # the plate barcode header row from the customer csv file
  #
  class PcrCyclesBinnedPlate::CsvFile::WellDetailsHeaderBase
    include ActiveModel::Validations

    # Return the index of the respective column.
    # These are common columns shared by all versions of the csv file.
    attr_reader :well_column,
                :concentration_column,
                :sanger_sample_id_column,
                :supplier_sample_name_column,
                :input_amount_available_column,
                :input_amount_desired_column,
                :sample_volume_column,
                :diluent_volume_column,
                :pcr_cycles_column

    WELL_COLUMN = 'Well'
    CONCENTRATION_COLUMN = 'Concentration (nM)'
    SANGER_SAMPLE_ID_COLUMN = 'Sanger Sample Id'
    SUPPLIER_SAMPLE_NAME_COLUMN = 'Supplier Sample Name'
    INPUT_AMOUNT_AVAILABLE_COLUMN = 'Input amount available (fmol)'
    INPUT_AMOUNT_DESIRED_COLUMN = 'Input amount desired'
    SAMPLE_VOLUME_COLUMN = 'Sample volume'
    DILUENT_VOLUME_COLUMN = 'Diluent volume'
    PCR_CYCLES_COLUMN = 'PCR cycles'

    validates :well_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :concentration_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :sanger_sample_id_column,
              presence: {
                message: ->(object, _data) { "could not be found in: '#{object}'" }
              }
    validates :supplier_sample_name_column,
              presence: {
                message: ->(object, _data) { "could not be found in: '#{object}'" }
              }
    validates :input_amount_available_column,
              presence: {
                message: ->(object, _data) { "could not be found in: '#{object}'" }
              }
    validates :input_amount_desired_column,
              presence: {
                message: ->(object, _data) { "could not be found in: '#{object}'" }
              }
    validates :sample_volume_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :diluent_volume_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :pcr_cycles_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }

    #
    # Generates a well details header from the well details header row array
    #
    # @param [Array] row The array of fields extracted from the CSV file
    #
    def initialize(row)
      @row = row || []

      @well_column = index_of_header(WELL_COLUMN)
      @concentration_column = index_of_header(CONCENTRATION_COLUMN)
      @sanger_sample_id_column = index_of_header(SANGER_SAMPLE_ID_COLUMN)
      @supplier_sample_name_column = index_of_header(SUPPLIER_SAMPLE_NAME_COLUMN)
      @input_amount_available_column = index_of_header(INPUT_AMOUNT_AVAILABLE_COLUMN)
      @input_amount_desired_column = index_of_header(INPUT_AMOUNT_DESIRED_COLUMN)
      @sample_volume_column = index_of_header(SAMPLE_VOLUME_COLUMN)
      @diluent_volume_column = index_of_header(DILUENT_VOLUME_COLUMN)
      @pcr_cycles_column = index_of_header(PCR_CYCLES_COLUMN)

      initialize_pipeline_specific_columns
    end

    #
    # Outputs the header as a string
    #
    # @return [<String] Outputs the raw header data
    #
    def to_s
      @row.join(',')
    end

    private

    def initialize_pipeline_specific_columns
      raise '#initialize_pipeline_specific_columns must be implemented on subclasses'
    end

    #
    # Returns the index of the given column name. Returns nil if the column can't be found.
    # Uses strip and case insensitive matching
    #
    # @param [String] column_header The header of the column to find
    #
    # @return [Int,nil] The index of the header in the column list. nil is missing.
    #
    def index_of_header(column_header)
      @row.index { |value| value.respond_to?(:strip) && column_header.casecmp?(value.strip) }
    end
  end
end
