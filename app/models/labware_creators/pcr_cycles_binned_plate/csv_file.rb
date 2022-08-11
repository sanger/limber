# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate'

  #
  # Takes the user uploaded csv file, validates the content and extracts the well information.
  # This file will be downloaded from Limber based on the quantification results, then sent out
  # to and filled in by the customer. It describes how to dilute and bin the samples together
  # in the child dilution plate.
  #
  class PcrCyclesBinnedPlate::CsvFile
    include ActiveModel::Validations
    extend NestedValidation

    REQUEST_METADATA_FIELDS = %w[
      sample_volume
      diluent_volume
      pcr_cycles
      submit_for_sequencing
      sub_pool
      coverage
      bait_library
    ].freeze

    validate :correctly_parsed?
    validates :plate_barcode_header_row, presence: true
    validates_nested :plate_barcode_header_row
    validates :well_details_header_row, presence: true
    validates_nested :well_details_header_row
    validates_nested :transfers, if: :correctly_formatted?

    delegate :well_column,
             :concentration_column,
             :sanger_sample_id_column,
             :supplier_sample_name_column,
             :input_amount_available_column,
             :input_amount_desired_column,
             :sample_volume_column,
             :diluent_volume_column,
             :pcr_cycles_column,
             :submit_for_sequencing_column,
             :sub_pool_column,
             :coverage_column,
             :hyb_panel_column,
             to: :well_details_header_row

    #
    # Passing in the file to be parsed, the configuration that holds validation range thresholds, and
    # the parent plate barcode for validation that we are processing the correct file.
    def initialize(file, config, parent_barcode)
      initialize_variables(file, config, parent_barcode)
    rescue StandardError => e
      reset_variables
      @parse_error = e.message
    ensure
      file.rewind
    end

    def initialize_variables(file, config, parent_barcode)
      @config = Utility::PcrCyclesCsvFileUploadConfig.new(config)
      @parent_barcode = parent_barcode
      @data = CSV.parse(file.read)
      remove_bom
      @parsed = true
    end

    def reset_variables
      @config = nil
      @parent_barcode = nil
      @data = []
      @parsed = false
    end

    #
    # Extracts those well details from the uploaded csv file that we will store in the request metaadata
    #
    # @return [Hash] eg. { 'A1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0,
    # 'pcr_cycles' => 14, 'submit_for_sequencing' => true, 'sub_pool' => 1, 'coverage' => 15 }, etc. }
    #
    def request_metadata_details
      @request_metadata_details ||= generate_request_metadata_details_hash
    end

    def skipped_wells
      @skipped_wells ||= []
    end

    def correctly_parsed?
      return true if @parsed

      errors.add(:base, "Could not read csv: #{@parse_error}")
      false
    end

    def plate_barcode_header_row
      @plate_barcode_header_row ||= PlateBarcodeHeader.new(@parent_barcode, @data[0]) if @data[0]
    end

    # Returns the contents of the header row for the well detail columns
    def well_details_header_row
      @well_details_header_row ||= WellDetailsHeader.new(@data[2]) if @data[2]
    end

    private

    # remove byte order marker if present
    def remove_bom
      return unless @data.present? && @data[0][0].present?

      # byte order marker will appear at beginning of in first string in @data array
      s = @data[0][0]

      # NB. had to make byte order marker string mutable here otherwise get frozen string error
      bom = +"\xEF\xBB\xBF"
      s_mod = s.gsub!(bom.force_encoding(Encoding::BINARY), '')

      @data[0][0] = s_mod unless s_mod.nil?
    end

    def transfers
      @transfers ||= calculate_transfers
    end

    def calculate_transfers
      # filter out sample rows we do not want transferred
      filtered_transfers = []
      @data[3..].each_with_index do |row_data, index|
        curr_row = Row.new(@config, well_details_header_row, index + 2, row_data)

        if curr_row.valid? && curr_row.do_not_transfer_sample
          skipped_wells << curr_row.well
        else
          filtered_transfers << curr_row
        end
      end

      filtered_transfers
    end

    # Gates looking for wells if the file is invalid
    def correctly_formatted?
      correctly_parsed? && plate_barcode_header_row.valid? && well_details_header_row.valid?
    end

    # Create the hash of well details from the file upload values
    def generate_request_metadata_details_hash
      return {} unless valid?

      transfers.each_with_object({}) do |row, request_metadata_details_hash|
        next if row.empty?

        field_to_value = REQUEST_METADATA_FIELDS.index_with { |field| row.send(field) }

        well_location = row.well
        request_metadata_details_hash[well_location] = field_to_value
      end
    end
  end
end
