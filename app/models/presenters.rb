# frozen_string_literal: true

module Presenters # rubocop:todo Style/Documentation
  def self.lookup_for(labware)
    presentation_classes = Settings.purposes[labware.purpose&.uuid || :unknown]

    if presentation_classes
      presentation_classes[:presenter_class].constantize
    else
      return Presenters::UnknownPlatePresenter if labware.plate?
      return Presenters::UnknownTubePresenter if labware.tube?

      raise UnknownLabwareType
    end
  end
end
