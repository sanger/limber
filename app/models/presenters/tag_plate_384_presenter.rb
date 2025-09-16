# frozen_string_literal: true

module Presenters
  # This presenter enables printing labels for 'Tag Plate - 384' plates.
  class TagPlate384Presenter < UnknownPlatePresenter
    def label
      label_class = purpose_config.fetch(:label_class) || 'Labels::Plate384SingleLabel'
      label_class.constantize.new(labware)
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
