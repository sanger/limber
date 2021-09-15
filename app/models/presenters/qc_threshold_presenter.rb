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

    def max
      @max ||= configuration.fetch(:max) { percentage? ? 100 : max_result + range_buffer }
    end

    def min
      @min ||= configuration.fetch(:min) { percentage? ? 0 : min_result - range_buffer }
    end

    def units
      @units ||= configuration.fetch(:units) do
        unique_units.min.units
      end
    rescue ArgumentError => e
      e.message
    end

    def default
      configuration.fetch(:default_threshold, 0)
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
