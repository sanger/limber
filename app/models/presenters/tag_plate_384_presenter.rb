# frozen_string_literal: true

module Presenters
  # This presenter enables printing labels for 'Tag Plate - 384' plates using the 384-well plate single label template.
  class TagPlate384Presenter < UnknownPlatePresenter
    def label
      Labels::Plate384SingleLabel.new(labware)
    end

    def add_unknown_plate_warnings
      errors.add(
        :plate,
        "type '#{labware.purpose_name}' is not a limber plate. " \
          'You can still use this page to print labels.'
      )
    end
  end
end
