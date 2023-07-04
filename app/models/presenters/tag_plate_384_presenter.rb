# frozen_string_literal: true

module Presenters
  # This presenter enables printing labels for 'Tag Plate - 384' plates using the 384-well plate single label template.
  class TagPlate384Presenter < UnknownPlatePresenter
    def label
      Labels::Plate384SingleLabel.new(labware)
    end
  end
end
