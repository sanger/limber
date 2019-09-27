# frozen_string_literal: true

module PlateHelper
  class WellFailingPresenter < BasicObject
    def initialize(form, presenter)
      @form = form
      @_presenter = presenter
    end

    def aliquot_partial
      'well_failing_aliquot'
    end

    delegate_missing_to :_presenter
    attr_reader :form, :_presenter
  end

  def fail_wells_presenter_from(form, presenter)
    WellFailingPresenter.new(form, presenter)
  end

  # Returns an array of all pre-capture pools sorted in column order based on the first
  # well in the pool.
  # We rely on the fact that hashes maintain insert order, and walk the wells in column
  # order. Each time we see a pre-capture pool for the first time, it gets inserted into the hash.
  # This gets passed to our javascript via ajax.
  # @note Javascript objects are not explicitly ordered, hence the need to pass an array here.
  #
  # @param current_plate [Sequencescape::Api::V2::Plate] The plate from which to extract the pre-cap pools
  #
  # @return [Array] An array of basic pool information
  # @example Example output
  #   [{ pool_id: '123', wells: ['A1','B1','D1'] }, { pool_id: '122', wells: ['C1','E1','F1'] }]
  def sorted_pre_cap_pool_json(current_plate)
    current_plate.wells_in_columns.each_with_object({}) do |well, pool_store|
      next unless well.passed?

      well.incomplete_requests.each do |request|
        next unless request.pre_capture_pool

        pool_id = request.pre_capture_pool.id
        pool_store[pool_id] ||= { pool_id: pool_id, wells: [] }
        pool_store[pool_id][:wells] << well.location
      end
    end.values.to_json.html_safe
  end

  def pools_by_id(pools)
    pools_by_position = pools.each_with_object({}) do |(key, value), result|
      result[key] = WellHelpers.sort_in_column_order(value['wells']).first
    end.sort_by { |_k, v| WellHelpers.well_coordinate(v) }.map.with_index { |v, i| [v.first, i + 1] }.to_h

    {}.tap do |h|
      pools.each do |key, value|
        value['wells'].each do |well|
          h[well] = pools_by_position[key]
        end
      end
    end
  end
end
