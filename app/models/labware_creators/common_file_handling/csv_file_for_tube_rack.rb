# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  #
  # This is an abstract class for handling tube rack csv files.
  #
  # Takes the user uploaded tube rack scan csv file, validates the content and extracts the information.
  #
  # This version of the rack scan file contains 2 columns, the first is the tube location (coordinate within rack)
  # and the second is the tube barcode.
  #
  # Example of file content (NB. no header line):
  # A1,FX05653780
  # A2,NO READ
  # etc.
  #
  class CommonFileHandling::CsvFileForTubeRack < CommonFileHandling::CsvFileBase
    validates_nested :tube_rack_scan
    validate :check_no_duplicate_rack_positions
    validate :check_no_duplicate_tube_barcodes

    NO_TUBE_TEXTS = ['NO READ', 'NOSCAN', ''].freeze
    NO_DUPLICATE_RACK_POSITIONS_MSG = 'contains duplicate rack positions (%s)'
    NO_DUPLICATE_TUBE_BARCODES_MSG = 'contains duplicate tube barcodes (%s)'

    #
    # Extracts tube details by rack location from the uploaded csv file.
    # This hash is useful when we want the details for a rack location.
    #
    # @return [Hash] e.g. { 'A1' => { details for this location }, 'B1' => etc. }
    #
    def position_details
      @position_details ||= generate_position_details_hash
    end

    # This hash is useful when we want to know the location of a tube barcode
    # within the rack.
    #
    # @return [Hash] eg. { 'FX00000001' => 'A1', 'FX00000002 => 'B1' etc. }
    #
    def location_by_barcode_details
      @location_by_barcode_details ||=
        position_details.each_with_object({}) { |(position, details), hash| hash[details['tube_barcode']] = position }
    end

    private

    # Returns an array of Row objects representing the tube rack scan data in the CSV file.
    #
    # @return [Array<Row>] An array of Row objects.
    def tube_rack_scan
      @tube_rack_scan ||=
        @data[0..].each_with_index.map do |row_data, index|
          CommonFileHandling::CsvFile::RowForTubeRack.new(index, row_data)
        end
    end

    # Checks for duplicate rack positions in the tube rack scan.
    # If any duplicates are found, an error message is added to the errors object.
    # The error message includes the duplicated rack positions.
    # This method is used to ensure that each rack position in the tube rack scan is unique.
    def check_no_duplicate_rack_positions
      return unless @parsed

      duplicated_rack_positions =
        tube_rack_scan.group_by(&:tube_position).select { |_position, tubes| tubes.size > 1 }.keys.join(',')

      return if duplicated_rack_positions.empty?

      errors.add(:base, format(NO_DUPLICATE_RACK_POSITIONS_MSG, duplicated_rack_positions))
    end

    # Checks for duplicate tube barcodes in the tube rack scan.
    # If any duplicates are found, they are added to the errors object.
    # The error message includes the duplicated tube barcodes.
    # 'NO READ' and 'NOSCAN' values are ignored and not considered as duplicates.
    # This method is used to ensure that each tube barcode in the tube rack scan is unique.
    def check_no_duplicate_tube_barcodes
      return unless @parsed

      duplicates = tube_rack_scan.group_by(&:tube_barcode).select { |_tube_barcode, tubes| tubes.size > 1 }.keys

      # remove any NO READ or NOSCAN or empty string values from the duplicates
      duplicates = duplicates.reject { |barcode| NO_TUBE_TEXTS.include?(barcode) }

      return if duplicates.empty?

      errors.add(:base, format(NO_DUPLICATE_TUBE_BARCODES_MSG, duplicates.join(',')))
    end

    # Generates a hash of position details based on the tube rack scan data in the CSV file.
    #
    # @return [Hash] A hash of position details, where the keys are positions and the values
    # are hashes containing the tube barcode for each position.
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
        position_details_hash[position] = format_position_details(row)
      end
    end

    # Override in subclasses if needed.
    # Formats the tube barcode details for a given row.
    # This method strips leading and trailing whitespace from the tube barcode and converts it to uppercase.
    # @param row [CSV::Row] The row of the CSV file.
    # @return [Hash] Hash containing the formatted tube barcode.
    def format_position_details(row)
      { 'tube_barcode' => format_barcode(row.tube_barcode) }
    end

    # Formats the given barcode.
    # This method removes leading and trailing whitespace from the barcode and converts it to uppercase.
    # @param barcode [String] The barcode to format.
    # @return [String] The formatted barcode.
    def format_barcode(barcode)
      barcode.strip.upcase
    end
  end
end
