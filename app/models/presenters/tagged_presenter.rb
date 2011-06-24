module Presenters
  class TaggedPresenter < PlatePresenter
    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'
  end
end
