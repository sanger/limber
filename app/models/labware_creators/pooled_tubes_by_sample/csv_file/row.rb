# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pooled_tubes_by_sample/csv_file'

  #
  # Provides a simple wrapper for handling and validating an individual row
  # A row in this file should contain a tube location (coordinate within rack) and a tube barcode e.g. Location, Barcode
  #
  class PooledTubesBySample::CsvFile::Row
    include ActiveModel::Validations

    TUBE_LOCATION_NOT_RECOGNISED = 'contains an invalid coordinate, in %s'
    BARCODE_MISSING = 'cannot be empty, in %s'

    attr_reader :position, :barcode, :index

    validates :position,
              inclusion: {
                in: WellHelpers.column_order,
                message: ->(object, _data) { TUBE_LOCATION_NOT_RECOGNISED % object }
              },
              unless: :empty?
    validates :barcode, presence: { message: ->(object, _data) { BARCODE_MISSING % object } }

    def initialize(index, row_data)
      @index = index
      @row_data = row_data

      # initialize supplied fields
      @position = (@row_data[0] || '').strip.upcase
      @barcode = (@row_data[1] || '').strip.upcase
    end

    def to_s
      @position.present? ? "row #{index + 2} [#{@position}]" : "row #{index + 2}"
    end

    def empty?
      @row_data.empty? || @row_data.compact.empty?
    end
  end
end
