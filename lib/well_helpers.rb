module WellHelpers
  COLUMNS_RANGE = (1..12).freeze
  ROWS_RANGE = ('A'..'H').freeze

  # Returns an array of all well names in column order
  #
  # @return [Array] well names in column order ie. A1, B1, C1 ...
  def self.column_order
    @column_order ||= COLUMNS_RANGE.map { |c| ROWS_RANGE.map { |r| "#{r}#{c}".freeze }}.flatten.freeze
  end

  # Returns the name of the well at the given co-ordinates
  # eg.
  # `WellHelpers.well_name(2,3) #=> 'D3'`
  # @param [Int] row The row co-ordinate, zero indexed
  # @param [Type] column The column co-ordinate, zero indexed
  # @return [String] the well name, eg. A1
  def self.well_name(row,column)
    "#{ROWS_RANGE.to_a[row]}#{COLUMNS_RANGE.to_a[column]}"
  end

  # Returns the name of the well at the provided index.
  # eg.
  # `WellHelpers.column_index(2) #=> 'C1'`
  # @param [Type] index describe index
  # @return [Type] description of returned object
  def self.well_at_column_index(index)
    column_order[index]
  end

end
