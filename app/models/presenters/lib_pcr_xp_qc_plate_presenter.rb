module Presenters
  class LibPcrXpQcPlatePresenter < QcPlatePresenter

  write_inheritable_attribute :robot_controlled_states, {
    :pending => 'lib-pcr-xp-lib-pcr-xp-qc'
  }


  end
end
