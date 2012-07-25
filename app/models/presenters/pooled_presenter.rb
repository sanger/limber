module Presenters
  class PooledPresenter < PlatePresenter
    def walk_source
      PlateWalking::Walker.new(plate_to_walk, plate_to_walk.wells)
    end

    def walk_destination
      PlateWalking::Walker.new(plate, plate.wells)
    end
  end
end
