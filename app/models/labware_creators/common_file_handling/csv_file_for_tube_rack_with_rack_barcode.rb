# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  #
  # This is an abstract class for handling tube rack csv files which contain rack barcodes.
  #
  # Takes the user uploaded tube rack scan csv file, validates the content and extracts the information.
  #
  # This version of the rack scan file contains 3 columns, the first is the tube rack barcode, the
  # second it the tube location (coordinate within rack) and the third is the tube barcode.
  #
  # Example of file content (NB. no header line):
  # TR00012345,A1,FX05653780
  # TR00012345,A2,NO READ
  # etc.
  #
  #
  class CommonFileHandling::CsvFileForTubeRackWithRackBarcode < CommonFileHandling::CsvFileForTubeRack
    validate :check_for_rack_barcodes_the_same

    RACK_BARCODES_NOT_CONSISTENT_MSG = 'should not contain different rack barcodes (%s)'

    private

    # Returns an array of Row objects representing the tube rack scan data in the CSV file.
    #
    # @return [Array<Row>] An array of Row objects.
    def tube_rack_scan
      @tube_rack_scan ||=
        @data[0..].each_with_index.map do |row_data, index|
          CommonFileHandling::CsvFile::RowForTubeRackWithRackBarcode.new(index, row_data)
        end
    end

    def check_for_rack_barcodes_the_same
      return unless @parsed

      tube_rack_barcodes = tube_rack_scan.group_by(&:tube_rack_barcode).keys

      return unless tube_rack_barcodes.size > 1

      barcodes_str = tube_rack_barcodes.join(',')
      errors.add(:base, format(RACK_BARCODES_NOT_CONSISTENT_MSG, barcodes_str))
    end

    def format_position_details(row)
      {
        'tube_rack_barcode' => format_barcode(row.tube_rack_barcode),
        'tube_barcode' => format_barcode(row.tube_barcode)
      }
    end
  end
end
