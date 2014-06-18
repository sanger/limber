module Presenters
  class ShearPlatePresenter < StandardPresenter

    write_inheritable_attribute :robot_controlled_states, {
      :pending => 'cherrypick-to-shear'
    }

  end
end
