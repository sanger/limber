# frozen_string_literal: true

module Presenters # rubocop:todo Style/Documentation
  def self.lookup_for(labware)
    presentation_classes = Settings.purposes[labware.purpose&.uuid || :unknown]
    return presentation_classes[:presenter_class].constantize if presentation_classes

    if labware.plate?
      return Presenters::TagPlate384Presenter if labware.purpose.name == 'Tag Plate - 384'
      return Presenters::UnknownPlatePresenter
    end

    return Presenters::UnknownTubePresenter if labware.tube?

    raise UnknownLabwareType
  end
end
