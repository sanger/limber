# frozen_string_literal: true

module Presenters
  #
  # The CardinalPoolsPlatePresenter is used for plates that have
  # a pool in a well, where a pool is a group of untagged samples
  #
  class CardinalPoolsPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    self.aliquot_partial = 'untagged_pools_aliquot'

    MAX_COLUMNS = 12

    # returns the id of the pool in a well
    # e.g. (36 / 12) + 1, would be the pool for well D1
    # TODO: maybe this could be refectored to use the standard_aliquot partial
    def get_pool_group_id(well)
      (labware.wells.index(well) / MAX_COLUMNS).to_i + 1
    end
  end
end
