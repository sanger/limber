module Presenters
  class PooledPresenter < PlatePresenter
    include Presenters::Statemachine

    def walk_source
      PlateWalking::Walker.new(plate_to_walk.wells)
    end

    def walk_destination
      PlateWalking::Walker.new(plate.wells)
    end
  end
end
