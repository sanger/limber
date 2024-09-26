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
    DEFAULT_DECIMAL_PLACES = 2

    attr_reader :name, :configuration, :results, :key

    def initialize(key, results, configuration)
      @key = key
      @name = configuration.fetch(:name, key)
      @results = results
      @configuration = configuration
    end

    #
    # The maximum value for the slider. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the maximum observed
    # value. (Or 100 if it's a percentage)
    #
    # @return [Float] The maximum value to use for the range
    #
    def max
      @max ||= configuration.fetch(:max) { percentage? ? 100 : max_result + range_buffer }.ceil(decimal_places)
    end

    #
    # The minimum value for the slider. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the minimum observed
    # value. (Or 0 if it's a percentage)
    #
    # @return [Float] The minimum value to use for the range
    #
    def min
      @min ||= configuration.fetch(:min) { percentage? ? 0 : min_result - range_buffer }.floor(decimal_places)
    end

    #
    # The units to use for the threshold. If not set in the thresholds section of
    # the purpose configuration is calibrated based on the most sensitive
    # observed units
    #
    # @return [String] The units to use for the threshold
    #
    def units
      @units ||= configuration.fetch(:units) { unique_units.min.units }
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
    # Indicates if the field should be enabled. Returns false if there are no QC
    # results for thresholds to work with or the units used for the wells can't
    # be directly converted.
    #
    # @return [Boolean]
    #
    def enabled?
      results? && compatible_units?
    end

    #
    # UI ready text to display to the user if the field is not enabled.
    #
    # @return [String]
    #
    def error
      return 'There are no QC results of this type to apply a threshold.' unless results?
      return if compatible_units?

      units = unique_units.map(&:units).join(', ')
      "Incompatible units #{units}. Automatic thresholds disabled."
    end

    def value_for(qc_result)
      qc_result.unit_value.convert_to(units).scalar.to_f
    rescue ArgumentError
      nil
    end

    def options
      configured_default = configuration[:default_threshold]
      return unless configured_default

      yield configured_default, "#{configured_default} #{units}"
    end

    def step
      (10**-decimal_places).to_f
    end

    private

    def decimal_places
      configuration.fetch(:decimal_places, DEFAULT_DECIMAL_PLACES)
    end

    def results?
      results.any?
    end

    def compatible_units?
      unique_units.all? { |unit| unit.compatible?(units) }
    end

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
    # our most extreme values.
    def range_buffer
      @range_buffer ||= (max_result - min_result) * RANGE_EXPANSION / 100
    end
  end

  def initialize(plate, configuration)
    @plate = plate
    @configuration = configuration.stringify_keys || {}
  end

  def thresholds
    indexed_thresholds.values
  end

  def value_for(qc_result)
    indexed_thresholds[qc_result.key]&.value_for(qc_result)
  end

  private

  def indexed_thresholds
    @indexed_thresholds ||=
      configuration.keys.index_with do |key|
        Threshold.new(key, well_results.fetch(key, []), configuration.fetch(key, {}))
      end
  end

  #
  # Returns a hash of all well results indexed by the key (eg. molarity)
  #
  # @return [Hash<key: String, value: Array<Sequencescape::Api::V2::QcResult >>] QcResults indexed by key
  #
  def well_results
    @well_results ||= plate.wells.flat_map(&:all_latest_qc).group_by(&:key)
  end

  attr_reader :configuration, :plate
end
