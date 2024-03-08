# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  #
  # This is an abstract class for handling csv files.
  #
  class CommonFileHandling::CsvFileBase
    include ActiveModel::Validations
    extend NestedValidation

    validate :correctly_parsed?

    def initialize(file)
      initialize_variables(file)
    rescue StandardError => e
      reset_variables
      @parse_error = e.message
    ensure
      file.rewind
    end

    # Override in subclass if needed
    def initialize_variables(file)
      @filename = file.original_filename
      @data = CSV.parse(file.read)
      remove_bom
      @parsed = true
    end

    # Override in subclass if needed
    def reset_variables
      @parent_barcode = nil
      @filename = nil
      @data = []
      @parsed = false
    end

    # Override in subclass if needed
    def correctly_parsed?
      return true if @parsed

      errors.add(:base, "Could not read csv: #{@parse_error}")
      false
    end

    private

    # Removes the byte order marker (BOM) from the first string in the @data array, if present.
    #
    # @return [void]
    def remove_bom
      return unless @data.present? && @data[0][0].present?

      # byte order marker will appear at beginning of in first string in @data array
      s = @data[0][0]

      # NB. had to make byte order marker string mutable here otherwise get frozen string error
      bom = +"\xEF\xBB\xBF"
      s_mod = s.gsub!(bom.force_encoding(Encoding::BINARY), '')

      @data[0][0] = s_mod unless s_mod.nil?
    end
  end
end
