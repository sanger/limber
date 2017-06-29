# frozen_string_literal: true

module LabwareCreators
  require_dependency 'labware_creators/custom_pooled_tubes'

  # Takes the user uploaded csv file and extracts the pool information
  class CustomPooledTubes::CsvFile
    SOURCE_COLUMN = 'Source Well'
    DEST_COLUMN = 'Dest. well'

    include ActiveModel::Validations

    validate :correctly_parsed?
    validates :header_row, presence: true
    validates :source_column, presence: { message: ->(object, _data) { "could not be found in header row: #{object.header_row.join(',')}" } }
    validates :destination_column, presence: { message: ->(object, _data) { "could not be found in header row: #{object.header_row.join(',')}" } }
    validate :recognized_wells, if: :correctly_formatted?

    def initialize(file)
      @data = CSV.parse(file.read)
      @parsed = true
    rescue => e
      @data = []
      @parsed = false
      @parse_error = e.message
    ensure
      file.rewind
    end

    #
    # Extracts pool information from the uploaded csv file
    #
    # @return [Hash] eg. { '1' => { 'wells' => ['A1','B1','C1'] } }
    #
    def pools
      @pools ||= generate_pools_hash
    end

    def correctly_parsed?
      return true if @parsed
      errors.add(:base, "Could not read csv: #{@parse_error}")
      false
    end

    # Returns the contents of the header row
    def header_row
      @data[0]
    end

    #
    # Returns the index of the source column. Uses strip and case insensitive matching
    #
    #
    # @return [Integer] Index of the column
    #
    def source_column
      @source_column ||= header_row.index { |value| SOURCE_COLUMN.casecmp?(value.strip) }
    end

    #
    # Returns the index of the destination column. Uses strip and case insensitive matching
    #
    #
    # @return [Integer] Index of the column
    #
    def destination_column
      header_row.index { |value| DEST_COLUMN.casecmp?(value.strip) }
    end

    def recognized_wells
      listed_wells.reduce(true) do |valid, well|
        if WellHelpers.column_order.include?(well.strip.upcase)
          valid
        else
          errors.add(:base, "Couldn't recognise the well named: '#{well}'")
          false
        end
      end
    end

    private

    # Gates looking for wells if the file is invalid
    def correctly_formatted?
      correctly_parsed? && source_column && destination_column
    end

    # An array containing all
    def listed_wells
      pools.values.reduce([]) do |wells, pool|
        wells.concat(pool['wells'])
      end
    end

    def pool_hash
      { 'wells' => [] }
    end

    def generate_pools_hash
      pools = Hash.new { |hash, pool_name| hash[pool_name] = pool_hash }
      @data[1..-1].each do |row|
        pool_name = (row[destination_column] || '').strip.downcase
        next if pool_name.empty?
        pools.dig(pool_name, 'wells') << (row[source_column] || '').strip.upcase
      end
      pools
    end
  end
end
