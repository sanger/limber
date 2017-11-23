# frozen_string_literal: true

module WellHelpers
  COLUMNS_RANGE = {
    96 => (1..12).freeze,
    384 => (1..24).freeze
  }.freeze

  ROWS_RANGE = {
    96 => ('A'..'H').freeze,
    384 => ('A'..'P').freeze
  }.freeze

  def self.columns_range(size)
    COLUMNS_RANGE.fetch(size)
  end

  def self.rows_range(size)
    ROWS_RANGE.fetch(size)
  end

  # Returns an array of all well names in column order
  #
  # @return [Array] well names in column order ie. A1, B1, C1 ...
  def self.column_order(size = 96)
    columns_range(size).each_with_object([]) { |c, wells| rows_range(size).each { |r| wells << "#{r}#{c}" } }.freeze
  end

  # Returns an array of all well names in row order
  # Sequencescape returns some wells in column order. THis is primarily used to help
  # us mimic Sequencescape output in tests.
  #
  # @return [Array] well names in row order ie. A1, A2, A3 ...
  def self.row_order(size = 96)
    rows_range(size).each_with_object([]) { |r, wells| columns_range(size).each { |c| wells << "#{r}#{c}" } }.freeze
  end

  # Returns the index of the well by column
  # @param [String] well The well name eg. A1
  # @return [Int] the index, eg. 0
  def self.index_of(well, size = 96)
    column_order(size).index(well)
  end

  # Returns the name of the well at the given co-ordinates
  # eg.
  # `WellHelpers.well_name(2,3) #=> 'D3'`
  # @param [Int] row The row co-ordinate, zero indexed
  # @param [Int] column The column co-ordinate, zero indexed
  # @return [String] the well name, eg. A1
  def self.well_name(row, column)
    row_name = ('A'.getbyte(0) + row).chr
    "#{row_name}#{column + 1}"
  end

  # Returns the name of the well at the provided index.
  # eg.
  # `WellHelpers.column_index(2) #=> 'C1'`
  # @param [Int] index Well index by column
  # @return [String] string name of the well
  def self.well_at_column_index(index, size = 96)
    column_order(size)[index]
  end

  #
  # Returns a new array sorted into column order
  # eg. sort_in_column_order(['A1', 'A2', 'B1']) => ['A1', 'B1', 'A2']
  #
  # @param [Array<String>] wells Array of well names to sort
  #
  # @return [Array<String>] Array of well names sorted in column order
  #
  def self.sort_in_column_order(wells, size = 96)
    wells.sort_by { |well| index_of(well, size) }
  end

  #
  # Compacts the provided well range into an easy to read summary.
  # eg. formatted_range(['A1', 'B1', 'C1','A2','A5','B5']) => 'A1-C1,A2,A5-B5'
  # Mostly this will just be start_well-end_well
  #
  # @param [Array<String>] wells Array of well names to format
  #
  # @return [String] A name describing the range
  #
  def self.formatted_range(wells, size = 96)
    sort_in_column_order(wells, size)
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
  def self.first_and_last_in_columns(wells, size = 96)
    sorted = sort_in_column_order(wells, size)
    [sorted.first, sorted.last]
  end
end
