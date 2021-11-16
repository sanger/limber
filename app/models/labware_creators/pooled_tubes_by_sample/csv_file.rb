# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pooled_tubes_by_sample'

  #
  # Takes the user uploaded tube rack scan csv file, validates the content and extracts the information.
  # This file will be used to determine and create the fluidX tubes into which samples will be transferred,
  # and the tube locations then used to create a driver file for the liquid handler.
  # Example of content (NB. no header):
  # A1, FR05653780
  # A2, NO READ
  # etc.
  #
  class PooledTubesBySample::CsvFile
    include ActiveModel::Validations
    extend NestedValidation

    validate :correctly_parsed?
    validates_nested :tube_rack_scan, if: :correctly_formatted?

    NO_TUBE_TEXTS = ['NO READ'].freeze

    #
    # Passing in the file to be parsed, the configuration from the purposes yml, and
    # the parent plate barcode for validation that we are processing the correct file.
    def initialize(file, parent_barcode)
      initialize_variables(file, parent_barcode)
    rescue StandardError => e
      reset_variables
      @parse_error = e.message
    ensure
      file.rewind
    end

    def initialize_variables(file, parent_barcode)
      @parent_barcode = parent_barcode
      @data = CSV.parse(file.read)
      remove_bom
      @parsed = true
    end

    def reset_variables
      @parent_barcode = nil
      @data = []
      @parsed = false
    end

    #
    # Extracts tube location details from the uploaded csv file
    #
    # @return [Hash] eg. { 'A1' => { 'barcode' => AB12345678 }, 'B1' => etc. }
    #
    def position_details
      @position_details ||= generate_position_details_hash
    end

    def correctly_parsed?
      return true if @parsed

      errors.add(:base, "Could not read csv: #{@parse_error}")
      false
    end

    private

    # remove byte order marker if present
    def remove_bom
      return unless @data.present? && @data[0][0].present?

      # byte order marker will appear at beginning of in first string in @data array
      s = @data[0][0]

      # NB. had to make byte order marker string mutable here otherwise get frozen string error
      bom = +"\xEF\xBB\xBF"
      s_mod = s.gsub!(bom.force_encoding(Encoding::BINARY), '')

      @data[0][0] = s_mod unless s_mod.nil?
    end

    def tube_rack_scan
      @tube_rack_scan ||= @data[0..].each_with_index.map do |row_data, index|
        Row.new(index, row_data)
      end
    end

    # Gates looking for tube locations if the file is invalid
    def correctly_formatted?
      correctly_parsed?
    end

    # Create the hash of tube location details from the file upload values
    # TODO does this need to be sorted in position order?
    def generate_position_details_hash
      return {} unless valid?

      tube_rack_scan.each_with_object({}) do |row, position_details_hash|
        # ignore blank rows in file
        next if row.empty?

        # filter out locations with no tube scanned
        next if NO_TUBE_TEXTS.include? row.barcode.strip.upcase

        position = row.position
        position_details_hash[position] = { 'barcode' => row.barcode.strip.upcase }
      end
    end
  end
end
