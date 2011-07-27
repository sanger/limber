module Presenters
  class TaggedPresenter < PlatePresenter
    include Presenters::Statemachine
    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'
  end
end
