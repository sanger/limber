# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/plate_split_to_tube_racks'

  #
  # Takes the user uploaded tube rack scan csv file, validates the content and extracts the information.
  # This file will be used to determine and create the fluidX tubes into which samples will be transferred,
  # and the tube locations then used to create a driver file for the liquid handler.
  # The filename of the file should also contain the tube rack barcode.
  # Example of file content (NB. no header line):
  # FX12345678, A1, FR05653780
  # FX12345678, A2, NO READ
  # etc.
  #
  class PlateSplitToTubeRacks::CsvFile
    include ActiveModel::Validations
    extend NestedValidation

    validate :correctly_parsed?
    validates_nested :tube_rack_scan, if: :correctly_formatted?

    NO_TUBE_TEXTS = ['NO READ', 'NOSCAN'].freeze

    def initialize(file)
      initialize_variables(file)
    rescue StandardError => e
      reset_variables
      @parse_error = e.message
    ensure
      file.rewind
    end

    def initialize_variables(file)
      @filename = file.original_filename
      @data = CSV.parse(file.read)
      remove_bom
      @parsed = true
    end

    def reset_variables
      @parent_barcode = nil
      @filename = nil
      @data = []
      @parsed = false
    end

    #
    # Extracts tube details by rack location from the uploaded csv file
    #
    # @return [Hash] eg. { 'A1' => { 'tube_rack_barcode' => 'FX12345678', 'tube_barcode' => AB12345678 }, 'B1' => etc. }
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

    # Removes the byte order marker (BOM) from the first string in the @data array, if present.
    #
    # @return [void]
    def remove_bom
      return unless @data.present? && @data[0][0].present?

      # byte order marker will appear at beginning of in first string in @data array
      s = @data[0][0]

      # NB. had to make byte order marker string mutable here otherwise get frozen string error
      bom = +"\xEF\xBB\xBF"
      s_mod = s.gsub!(bom.force_encoding(Encoding::BINARY), '')

      @data[0][0] = s_mod unless s_mod.nil?
    end

    # Returns an array of Row objects representing the tube rack scan data in the CSV file.
    #
    # @return [Array<Row>] An array of Row objects.
    def tube_rack_scan
      @tube_rack_scan ||= @data[0..].each_with_index.map { |row_data, index| Row.new(index, row_data) }
    end

    # Gates looking for tube locations if the file is invalid
    def correctly_formatted?
      correctly_parsed?
    end

    # Generates a hash of position details based on the tube rack scan data in the CSV file.
    #
    # @return [Hash] A hash of position details, where the keys are positions and the values
    # are hashes containing the tube rack barcode and tube barcode for each position.
    def generate_position_details_hash
      return {} unless valid?

      tube_rack_scan.each_with_object({}) do |row, position_details_hash|
        # ignore blank rows in file
        next if row.empty?

        # filter out locations with no tube scanned
        next if NO_TUBE_TEXTS.include? row.tube_barcode.strip.upcase

        position = row.tube_position

        # we will use this hash later to create the tubes and store the
        # rack barcode in the tube metadata
        position_details_hash[position] = {
          'tube_rack_barcode' => row.tube_rack_barcode.strip.upcase,
          'tube_barcode' => row.tube_barcode.strip.upcase
        }
      end
    end
  end
end
