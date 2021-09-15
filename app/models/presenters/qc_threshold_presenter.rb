# frozen_string_literal: true

# A QC threshold presenter is in charge of rendering the threshold sliders when
# making QC decisions. It aggregates information from the wells and the purpose
# configuration to present options for the selected parameters
class Presenters::QcThresholdPresenter
  # A threshold is a single QC attribute, and the configuration for the default
  # range, the units used, and whether there are any defaults
  class Threshold
    # The range slider, unless otherwise configured, will set its range based on
    # the maximum and minimum values observed. It will expand the range by the
    # percentage indicated here to ensure the maximum and minimum values don't
    # butt right up against the range limits
    RANGE_EXPANSION = 5
    attr_reader :name, :configuration, :results, :key

    def initialize(key, results, configuration)
      @key = key
      @name = configuration.fetch(:name, key)
      @results = results
      @configuration = configuration
    end

    #
    # The maximum value for the slider. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the maximum obserbved
    # vaule. (Or 100 ifd its a percentage)
    #
    # @return [Float] The maxmium value to use for the range
    #
    def max
      @max ||= configuration.fetch(:max) { percentage? ? 100 : max_result + range_buffer }
    end

    #
    # The minimum value for the slider. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the minimum obserbved
    # vaule. (Or 0 if its a percentage)
    #
    # @return [Float] The minimum value to use for the range
    #
    def min
      @min ||= configuration.fetch(:min) { percentage? ? 0 : min_result - range_buffer }
    end

    #
    # The units to use for the threshold. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the most sensitive
    # observed units
    #
    # @return [String] The units to use for the threshold
    #
    def units
      @units ||= configuration.fetch(:units) do
        unique_units.min.units
      end
    rescue ArgumentError
      unique_units.first
    end

    #
    # The default position for the slider. If not set in the thresholds section of
    # the purpose configuration is set to zero.
    #
    # @return [Float,Integer] The default slider position
    #
    def default
      configuration.fetch(:default_threshold, 0)
    end

    #
    # Indicates if the field should be enabled. Is disabled if the units used
    # for the wells can't be directly converted.
    #
    # @return [Boolean]
    #
    def enabled?
      unique_units.all? { |unit| unit.compatible?(units) }
    end

    #
    # Text that can be displayed to the user if the field is disabled.
    #
    # @return [String]
    #
    def error
      units = unique_units.map(&:units).join(', ')
      "Incompatible units #{units}. Automatic thresholds disabled." unless enabled?
    end

    private

    def unique_units
      results.map(&:units).uniq.map { |u| Unit.new(u) }
    end

    def percentage?
      units == '%'
    end

    def min_result
      results.min_by(&:unit_value).unit_value.convert_to(units).scalar.to_f
    end

    def max_result
      results.max_by(&:unit_value).unit_value.convert_to(units).scalar.to_f
    end

    # We add a buffer to the range to ensure our slider can move a little way past
    # our most extream values.
    def range_buffer
      @range_buffer ||= (max_result - min_result) * RANGE_EXPANSION / 100
    end
  end

  def initialize(plate, configuration)
    @plate = plate
    @configuration = configuration.stringify_keys || {}
  end

  def thresholds
    all_thresholds.map do |key|
      Threshold.new(key, well_results.fetch(key, []), configuration.fetch(key, {}))
    end
  end

  private

  #
  # Returns a hash of all well results indexed by the key (eg. molarity)
  #
  # @return [Hash<key: String, value: Array<Sequencescape::Api::V2::QcResult >>] QcResults indexed by key
  #
  def well_results
    @well_results ||= plate.wells.flat_map(&:all_latest_qc).group_by(&:key)
  end

  #
  # An array of all qc results associated with the plate or configuration.
  # Configured qc results are displayed first
  #
  # @return [Array<String>] All qc results associated with the plate or configuration
  #
  def all_thresholds
    (configuration.keys + well_results.keys).uniq
  end

  attr_reader :configuration, :plate
end
