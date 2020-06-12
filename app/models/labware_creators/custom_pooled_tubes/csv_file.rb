# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

module LabwareCreators # rubocop:todo Style/Documentation
  require_dependency 'labware_creators/custom_pooled_tubes'

  # Takes the user uploaded csv file and extracts the pool information
  # Also validates the content of the CSV file.
  class CustomPooledTubes::CsvFile
    include ActiveModel::Validations
    extend NestedValidation

    validate :correctly_parsed?
    validates :header_row, presence: true
    validates_nested :header_row
    validates_nested :transfers, if: :correctly_formatted?

    delegate :source_column, :destination_column, :volume_column, to: :header_row

    def initialize(file)
      @data = CSV.parse(file.read)
      @parsed = true
    rescue StandardError => e
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
      @header_row ||= Header.new(@data[0]) if @data[0]
    end

    private

    def transfers
      @transfers ||= @data[1..-1].each_with_index.map do |row_data, index|
        Row.new(header_row, index + 2, row_data)
      end
    end

    # Gates looking for wells if the file is invalid
    def correctly_formatted?
      correctly_parsed? && header_row.valid?
    end

    def generate_pools_hash
      return {} unless valid?

      pools = Hash.new { |hash, pool_name| hash[pool_name] = [] }
      transfers.each do |row|
        next if row.empty?

        pools[row.destination] << row.source
      end
      pools
    end
  end
end
