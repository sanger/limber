# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate'

  # Takes the user uploaded csv file and extracts the well information.
  # Also validates the content of the CSV file.
  class PcrCyclesBinnedPlate::CsvFile
    include ActiveModel::Validations
    extend NestedValidation

    validate :correctly_parsed?
    validates :header_row, presence: true
    validates_nested :header_row
    validates_nested :transfers, if: :correctly_formatted? # TODO: what is this for??

    delegate :well_column, :concentration_column, :sanger_sample_id_column,
    :supplier_sample_name_column, :input_amount_available_column, :input_amount_desired_column,
    :sample_volume_column, :diluent_volume_column, :pcr_cycles_column,
    :submit_for_sequencing_column, :sub_pool_column, :coverage_column, to: :header_row

    def initialize(file)
      @data = CSV.parse(file.read)
      @parsed = true
    rescue StandardError => e
      @data = []
      @parsed = false
      @parse_error = e.message
    ensure
      file.rewind
    end

    #
    # Extracts well details from the uploaded csv file
    #
    # @return [Hash] eg. { 'A1' => { TODO: structure of this hash? }
    #
    def well_details
      @well_details ||= generate_well_details_hash
    end

    def correctly_parsed?
      return true if @parsed

      errors.add(:base, "Could not read csv: #{@parse_error}")
      false
    end

    # Returns the contents of the header row
    def header_row
      @header_row ||= Header.new(@data[0]) if @data[0]
    end

    private

    def transfers
      @transfers ||= @data[1..-1].each_with_index.map do |row_data, index|
        Row.new(header_row, index + 2, row_data)
      end
    end

    # Gates looking for wells if the file is invalid
    def correctly_formatted?
      correctly_parsed? && header_row.valid?
    end

    def generate_well_details_hash
      return {} unless valid?

      well_details = Hash.new { |hash, well_locn| hash[well_locn] = [] }
      transfers.each do |row|
        next if row.empty?

        well_details[row.well] << row.pcr_cycles
      end
      well_details
    end
  end
end
