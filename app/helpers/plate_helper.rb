# frozen_string_literal: true

module PlateHelper # rubocop:todo Style/Documentation
  # Proxy object wrapping the form alongside the presenter.
  # This allows us to use the shared plate partial, but pass the form
  # object through to the custom aliquot partial
  # rubocop:disable Rails/HelperInstanceVariable
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
  # rubocop:enable Rails/HelperInstanceVariable

  def fail_wells_presenter_from(form, presenter)
    WellFailingPresenter.new(form, presenter)
  end

  # Proxy presenter for well marking functionality.
  # Inherits from WellFailingPresenter to reuse well handling logic
  # such as form integration and presenter behavior.
  #
  # Overrides `aliquot_partial` so that the shared plate partial
  # will render the correct custom aliquot template (`_well_marking_aliquot.html.erb`)
  class WellMarkingPresenter < WellFailingPresenter
    def aliquot_partial
      'well_marking_aliquot'
    end
  end

  def mark_wells_presenter_from(form, presenter)
    WellMarkingPresenter.new(form, presenter)
  end

  # Returns an array of all pre-capture pools for a plate, with wells sorted
  # into plate well column order. We rely on the fact that hashes maintain
  # insert order, and walk the wells in column order. Each time we see a
  # pre-capture pool for the first time, it gets inserted into the hash along
  # with the request Order id.
  # We then sort the pre-capture pool hashes within the array by their Order
  # ids, to get the pools into the right sequence. Requests are grouped into
  # Orders, each pre-capture pool has a different Order relating to the asset
  # group name entered on the submission manifest. Asset groups are created in
  # the sequence they are presented in the manifest. (Pre-capture pools are not
  # created sequentially in the same order as the asset groups on the manifest).
  # This sorted array gets passed to our javascript via ajax.
  # @note Javascript objects are not explicitly ordered, hence the need to pass
  # an array here.
  #
  # @param current_plate [Sequencescape::Api::V2::Plate] The plate from which to
  # extract the pre-cap pools
  #
  # @return [Array] An array of basic pool information
  # @example Example output
  #   [
  #    { pool_id: 123, order_id: 401, wells: ['A1','B1','D1'] },
  #    { pool_id: 122, order_id: 402, wells: ['C1','E1','F1'] }
  #   ]
  def sorted_pre_cap_pool_json(current_plate) # rubocop:todo Metrics/AbcSize
    unsorted =
      current_plate
        .wells_in_columns
        .each_with_object({}) do |well, pool_store|
        next unless well.passed?

        well.incomplete_requests.each do |request|
          next unless request.pre_capture_pool

          pool_id = request.pre_capture_pool.id
          pool_store[pool_id] ||= { pool_id: pool_id, order_id: request.order_id, wells: [] }
          pool_store[pool_id][:wells] << well.location
        end
      end
        .values

    # sort the pool hashes by Order id
    sorted = unsorted.sort_by { |k| k[:order_id] }
    sorted.to_json.html_safe # rubocop:todo Rails/OutputSafety
  end

  def well_under_represented?(well)
    return false unless well

    aliquot = well.aliquots.first
    return false unless aliquot

    return false unless aliquot.request.respond_to?(:poly_metadata)
    return false unless aliquot.request.poly_metadata

    aliquot.request.poly_metadata.any? { |pm| pm.key == LimberConstants::UNDER_REPRESENTED_KEY && pm.value == 'true' }
  end
end
