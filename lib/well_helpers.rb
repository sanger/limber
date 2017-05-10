# frozen_string_literal: true

module WellHelpers
  COLUMNS_RANGE = (1..12).freeze
  ROWS_RANGE = ('A'..'H').freeze

  # Returns an array of all well names in column order
  #
  # @return [Array] well names in column order ie. A1, B1, C1 ...
  def self.column_order
    @column_order ||= COLUMNS_RANGE.map { |c| ROWS_RANGE.map { |r| "#{r}#{c}" } }.flatten.freeze
  end

  # Returns the index of the well by column
  # @param [String] well The well name eg. A1
  # @return [Int] the index, eg. 0
  def self.index_of(well)
    column_order.index(well)
  end

  # Returns the name of the well at the given co-ordinates
  # eg.
  # `WellHelpers.well_name(2,3) #=> 'D3'`
  # @param [Int] row The row co-ordinate, zero indexed
  # @param [Int] column The column co-ordinate, zero indexed
  # @return [String] the well name, eg. A1
  def self.well_name(row, column)
    "#{ROWS_RANGE.to_a[row]}#{COLUMNS_RANGE.to_a[column]}"
  end

  # Returns the name of the well at the provided index.
  # eg.
  # `WellHelpers.column_index(2) #=> 'C1'`
  # @param [Int] index Well index by column
  # @return [String] string name of the well
  def self.well_at_column_index(index)
    column_order[index]
  end

  def self.formatted_range(wells)
    wells.sort_by { |well| index_of(well) }
         .slice_when { |previous_well, next_well| index_of(next_well) - index_of(previous_well) > 1 }
         .map { |range| [range.first, range.last].uniq.join('-') }
         .join(', ')
  end
end
