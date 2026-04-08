# frozen_string_literal: true

# Presenters handle the display of labware in the view.
module Presenters
  # Returns the presenter class for a labware from purpose config. It can be
  # specified as a string or hash with a name key. If found, the presenter
  # class name is transformed into the actual class.
  #
  # As a string:
  # <purpose_name>:
  #   presenter_class: <presenter_class_name>
  #
  # As a hash:
  # <purpose_name>:
  #   presenter_class:
  #     name: <presenter_class_name>
  #
  # The reason for the hash is to allow for additional options other than just
  # the class name.
  #
  # If the presenter class name is not found, it returns UnknownPlatePresenter
  # or UnknownTubePresenter for plates and tubes. Otherwise It will raise
  # UnknownLabwareType exception.
  #
  # @param labware [Labware] The labware to find the presenter for
  # @return [Class] The presenter class for the labware
  # @raise [UnknownLabwareType] If the presenter class is not found and labware type is not known
  # :reek:TooManyStatements
  def self.lookup_for(labware)
    cls = Settings.purposes.fetch(labware.purpose&.uuid, {})[:presenter_class]
    name = cls.is_a?(Hash) ? cls[:name] : cls
    return name.constantize if name.present?

    return Presenters::UnknownPlatePresenter if labware.plate?
    return Presenters::UnknownTubePresenter if labware.tube?
    return Presenters::UnknownTubeRackPresenter if labware.tube_rack?

    raise UnknownLabwareType
  end
end
