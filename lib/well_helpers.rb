# frozen_string_literal: true

# Provides a series of helper methos to assist with generating and processing well names
module WellHelpers
  # Provide model level wrappers for these methods. Requires the the including class
  # responds to #number_of_columns and #number of wells
  module Extensions
    def locations_in_rows
      WellHelpers.row_order(rows: number_of_rows, columns: number_of_columns)
    end

    def rows_range
      WellHelpers.rows_range(rows: number_of_rows)
    end

    def columns_range
      WellHelpers.columns_range(columns: number_of_columns)
    end
  end

  HORIZONTAL_RATIO = 3
  VERTICAL_RATIO = 2

  def self.default_columns(size)
    ((size / (VERTICAL_RATIO * HORIZONTAL_RATIO))**0.5).to_i * HORIZONTAL_RATIO
  end

  def self.default_rows(size)
    ((size / (VERTICAL_RATIO * HORIZONTAL_RATIO))**0.5).to_i * VERTICAL_RATIO
  end

  def self.columns_range(size = nil, columns: nil)
    number_columns = columns || default_columns(size)
    (1..number_columns)
  end

  def self.rows_range(size = nil, rows: nil)
    number_rows = rows || default_rows(size)
    ('A'..).take(number_rows)
  end

  # Returns an array of all well names in column order
  #
  # @return [Array] well names in column order ie. A1, B1, C1 ...
  def self.column_order(size = 96, rows: nil, columns: nil)
    columns_range(size, columns: columns)
      .each_with_object([]) { |c, wells| rows_range(size, rows: rows).each { |r| wells << "#{r}#{c}" } }
      .freeze
  end

  # Returns an array of all well names in row order
  #
  # @param [96,192] number of wells on the plate. Only valid for 3:2 ratio plate sizes
  # @return [Array] well names in column order ie. A1, A2, A3 ...
  def self.row_order(size = 96, rows: nil, columns: nil)
    rows_range(size, rows: rows)
      .each_with_object([]) { |r, wells| columns_range(size, columns: columns).each { |c| wells << "#{r}#{c}" } }
      .freeze
  end

  #
  # Returns a hash suitable for stamping an entire plate
  #
  # @param [Integer] size The size of the plate
  #
  # @return [Hash] eg. { 'A1' => 'A1', 'B1' => 'B1', ...}
  #
  def self.stamp_hash(size, rows: nil, columns: nil)
    column_order(size, rows: rows, columns: columns).each_with_object({}) { |well, hash| hash[well] = well }
  end

  # Returns the index of the well by column
  # @param [String] well The well name eg. A1
  # @return [Int] the index, eg. 0
  def self.index_of(well, size = 96)
    column_order(size).index(well) || raise("Unknown well #{well} on plate of size 96")
  end

  # Returns the name of the well at the given co-ordinates
  # e.g..
  # `WellHelpers.well_name(2,3) #=> 'D3'`
  # @param [Int] row The row co-ordinate, zero indexed
  # @param [Int] column The column co-ordinate, zero indexed
  # @return [String] the well name, eg. A1
  def self.well_name(row, column)
    row_name = ('A'.getbyte(0) + row).chr
    "#{row_name}#{column + 1}"
  end

  # Returns the name of the well at the provided index.
  # e.g..
  # `WellHelpers.column_index(2) #=> 'C1'`
  # @param [Int] index Well index by column
  # @return [String] string name of the well
  def self.well_at_column_index(index, size = 96)
    column_order(size)[index]
  end

  #
  # Returns a new array sorted into column order
  # e.g.. sort_in_column_order(['A1', 'A2', 'B1']) => ['A1', 'B1', 'A2']
  #
  # @param [Array<String>] wells Array of well names to sort
  #
  # @return [Array<String>] Array of well names sorted in column order
  #
  def self.sort_in_column_order(wells)
    wells.sort_by { |well| well_coordinate(well) }
  end

  #
  # Compacts the provided well range into an easy to read summary.
  # e.g.. formatted_range(['A1', 'B1', 'C1','A2','A5','B5']) => 'A1-C1,A2,A5-B5'
  # Mostly this will just be start_well-end_well
  #
  # @param [Array<String>] wells Array of well names to format
  #
  # @return [String] A name describing the range
  #
  def self.formatted_range(wells, size = 96)
    sort_in_column_order(wells)
      .slice_when { |previous_well, next_well| index_of(next_well, size) - index_of(previous_well, size) > 1 }
      .map { |range| [range.first, range.last].uniq.join('-') }
      .join(', ')
  end

  #
  # Extracts the first and last well (as sorted in column order) from the array
  #
  # @param [Array<String>] wells Array of well names to sort
  #
  # @return [Array<string>] ['first_well_name','last_well_name']
  #
  def self.first_and_last_in_columns(wells)
    sorted = sort_in_column_order(wells)
    [sorted.first, sorted.last]
  end

  #
  # Converts a well name to its co-ordinates
  #
  # @param [<String>] well Name of the well. Eg. A3
  #
  # @return [Array<Integer>] An array of two integers indicating column and row. eg. [0, 2]
  #
  def self.well_coordinate(well)
    [well[1..].to_i - 1, well.upcase.getbyte(0) - 'A'.getbyte(0)]
  end

  #
  # Converts a well name to its quadrant
  #
  # @param [String] well Name of the well. Eg. A3
  #
  # @return [Integer] The quadrant number eg. 1
  #
  def self.well_quadrant(well)
    col, row = well_coordinate(well)
    (2 * (col % 2)) + (row % 2)
  end
end
