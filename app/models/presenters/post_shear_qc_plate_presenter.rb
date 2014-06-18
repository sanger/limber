module Presenters
  class PostShearQcPlatePresenter < QcPlatePresenter

    write_inheritable_attribute :robot_controlled_states, {
      :pending => 'shear-post-shear'
    }

  end
end
